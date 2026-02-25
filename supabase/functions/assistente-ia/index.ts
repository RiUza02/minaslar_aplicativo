import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { GoogleGenerativeAI } from "npm:@google/generative-ai"
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

/// Busca o perfil do usuário no banco de dados para verificar suas permissões.
async function getUserProfile(supabaseAdmin: SupabaseClient, token: string) {
  // Valida o token e obtém os dados do usuário autenticado
  const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token);
  if (userError) {
    console.error('Erro ao obter usuário pelo token:', userError.message);
    return null;
  }
  if (!user) return null;

  // Busca o perfil correspondente na tabela 'usuarios'
  const { data: profile, error: profileError } = await supabaseAdmin
    .from('usuarios')
    .select('is_admin')
    .eq('id', user.id)
    .single();

  if (profileError) console.error('Erro ao buscar perfil do usuário:', profileError.message);
  
  return profile;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // VULNERABILIDADE CORRIGIDA: O status de 'admin' não é mais lido do cliente.
    // Ele será verificado de forma segura no servidor.
    const { pergunta } = await req.json()

    const geminiApiKey = Deno.env.get('GEMINI_API_KEY')
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!geminiApiKey) throw new Error("Chave do Gemini ausente.");

    // ==================================================================
    // PASSO DE SEGURANÇA: Validar o privilégio do usuário no backend
    // ==================================================================
    // 1. Cria um cliente Supabase com privilégios de administrador (service_role)
    const supabaseAdmin = createClient(supabaseUrl!, supabaseServiceKey!);

    // 2. Extrai o token de autenticação do cabeçalho da requisição
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) throw new Error("Cabeçalho de autorização ausente.");
    const token = authHeader.replace('Bearer ', '');

    // 3. Busca o perfil do usuário e define 'isAdmin' com base no banco de dados
    const userProfile = await getUserProfile(supabaseAdmin, token);
    const isAdmin = userProfile?.is_admin ?? false;
    // ==================================================================

    const genAI = new GoogleGenerativeAI(geminiApiKey);
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
    const dataHoje = new Date().toLocaleDateString('pt-BR');
    
    let dadosDoBanco = "";
    let regrasDaIA = "";

    // 📖 O MANUAL DO APLICATIVO MINASLAR
    // Aqui você escreve exatamente como o seu app funciona. Seja detalhista!
    const manualDoApp = `
    MANUAL COMPLETO DO APLICATIVO MINASLAR:

    --- CONCEITOS GERAIS ---
    - O aplicativo MinasLar serve para gerenciar clientes, orçamentos e finanças da empresa.
    - Existem dois tipos de usuários: 'Administrador' e 'Usuário'. Administradores têm acesso a todas as informações e funcionalidades, incluindo o Dashboard financeiro. Usuários comuns têm uma visão mais restrita.
    - A tela principal para administradores é o 'Painel', que mostra os serviços pendentes do dia.
    - A tela principal para usuários comuns também é o 'Painel'.

    --- GERENCIAMENTO DE CLIENTES ---
    - Como ver os clientes: Vá para a aba 'Clientes'. Lá você verá uma lista de todos os clientes.
    - Como encontrar um cliente: Na tela 'Clientes', use a barra de busca no topo para pesquisar por nome, bairro ou telefone. Você também pode ordenar a lista por 'Nome (A-Z)', 'Bairro (A-Z)' ou 'Último Serviço' (clientes atendidos mais recentemente aparecem primeiro).
    - Como cadastrar um novo cliente: Na tela 'Clientes', o administrador pode clicar no botão '+' no canto inferior direito. Isso abrirá um formulário para preencher os dados.
    - Como cadastrar um cliente rapidamente: Na tela de 'Novo Cliente', há um botão 'Importar Dados de Texto'. Você pode colar um texto com Nome, Telefone, Rua, Número e Bairro (um por linha) para preencher os campos automaticamente.
    - Como ver detalhes de um cliente: Clique em um cliente na lista. A tela de detalhes mostrará todas as informações dele, incluindo endereço, contatos e o histórico de todos os orçamentos já feitos.
    - Ações rápidas na tela de detalhes do cliente: Você pode tocar nos botões para ligar, enviar mensagem no WhatsApp ou abrir o endereço no Google Maps. Pressionar e segurar uma informação (como telefone ou endereço) a copia para a área de transferência.
    - Como editar um cliente: (Apenas Admin) Na tela de 'Detalhes do Cliente', clique no ícone de lápis (editar) na barra superior para alterar as informações.
    - Como excluir um cliente: (Apenas Admin) Na tela de 'Detalhes do Cliente', clique no ícone de lixeira na barra superior. ATENÇÃO: Isso apagará o cliente e TODOS os orçamentos associados a ele permanentemente.
    - O que é um 'Cliente Problemático'?: É uma marcação manual que o administrador pode fazer ao cadastrar ou editar um cliente para sinalizar que houve algum problema no passado. Ele fica destacado em vermelho na lista.

    --- GERENCIAMENTO DE ORÇAMENTOS E SERVIÇOS ---
    - Como ver todos os orçamentos: Vá para a aba 'Orçamentos'.
    - Como encontrar um orçamento: Na tela 'Orçamentos', use a barra de busca para pesquisar por título do serviço, nome do cliente ou descrição. Você pode ordenar por 'Mais Recentes', 'Atraso (Urgente)', 'Maior Valor' (admin) ou 'Cliente (A-Z)'.
    - Como criar um novo orçamento: (Apenas Admin) Na tela 'Orçamentos', clique no botão '+'. Você será levado à lista de clientes para escolher para quem é o serviço. Após escolher o cliente, o formulário de criação do orçamento aparecerá. Você também pode criar um orçamento diretamente da tela de 'Detalhes do Cliente'.
    - Como editar um orçamento: (Apenas Admin) Na tela de 'Detalhes do Orçamento', clique no botão flutuante de lápis (editar).
    - Como excluir um orçamento: (Apenas Admin) Na tela de 'Detalhes do Orçamento', clique no ícone de lixeira na barra superior.
    - Como marcar um orçamento como 'Entregue' ou 'Pendente': Na tela de 'Detalhes do Orçamento', há um botão para alternar o status.
    - O que é um orçamento 'Retorno'?: É um serviço marcado como 'Garantia' ou 'Revisão'. Isso pode ser definido na criação ou edição do orçamento.

    --- PAINEL DO DIA E ROTAS (FUNCIONALIDADE PRINCIPAL) ---
    - O que é o 'Painel': É a terceira aba (ícone de gráfico de barras). Ele mostra a lista de TODOS os serviços PENDENTES agendados para o dia atual. É a tela principal para organização diária.
    - Como ver os serviços de hoje: Acesse a aba 'Painel'.
    - Como gerar a rota otimizada do dia: (Apenas Admin) Na tela 'Painel', clique no botão flutuante azul com ícone de mapa. O aplicativo calculará a melhor rota entre sua localização atual e o endereço de todos os clientes do dia, e abrirá no Google Maps.
    - Ações rápidas no Painel: Cada card de serviço no painel tem botões para Ligar, enviar WhatsApp ou abrir o endereço daquele cliente específico no mapa.

    --- AGENDA / CALENDÁRIO ---
    - Como ver a agenda do mês: Vá para a aba 'Agenda'. Você verá um calendário.
    - Como ver os serviços de um dia específico: Toque em um dia no calendário. Uma lista dos serviços daquele dia aparecerá abaixo. Você pode clicar no botão 'Gerenciar Dia' para ir para uma tela focada apenas naquele dia.

    --- DASHBOARD (APENAS ADMIN) ---
    - O que é o 'Dashboard': É a primeira aba, exclusiva para administradores. Mostra um resumo financeiro e operacional.
    - Faturamento do Mês: Mostra o valor total faturado no mês corrente.
    - Gráfico de Faturamento: Mostra a evolução do faturamento nos últimos 6 meses.
    - Gráfico de Visão Geral: Compara o número de 'Orçamentos' criados, 'Clientes' novos e 'Retornos' de garantia nos últimos 6 meses.
    - Gráfico de Distribuição: Mostra a porcentagem de serviços agendados para o turno da 'Manhã' vs. 'Tarde'.
    - Como sincronizar os dados do Dashboard: Clique no ícone de sincronização (setas circulares) na barra superior do Dashboard. Isso recalcula todas as finanças com base nos orçamentos mais recentes. Use isso se achar que os dados estão desatualizados.

    --- PERFIL E EQUIPE ---
    - Como editar meu perfil: No 'Painel', clique no ícone de engrenagem (configurações) no canto superior esquerdo. Na tela de 'Equipe & Perfil', você pode expandir seu card para editar seu nome e telefone.
    - Como ver os contatos da equipe: Na mesma tela de 'Equipe & Perfil', há uma lista com os outros usuários do sistema. Você pode usar os botões para ligar ou enviar WhatsApp para eles.
    - Como sair do aplicativo (Logout): Na tela de 'Equipe & Perfil', clique no ícone de 'sair' no canto superior direito.

    --- CONTA E ACESSO ---
    - Como recuperar a senha: Na tela de Login, clique em 'Esqueci minha senha'. Digite seu e-mail para receber um código de verificação e siga as instruções.
    - Como criar uma conta: Na tela inicial, clique em 'CRIAR UMA NOVA CONTA'.
    - Confirmação de e-mail: Após criar uma conta, você precisa abrir seu e-mail e clicar no link de confirmação enviado antes de poder fazer o login.

    --- ASSISTENTE IA ---
    - O que é o Assistente: É a última aba. Você pode fazer perguntas em linguagem natural sobre como usar o aplicativo ou, se for admin, sobre dados financeiros.
    - Exemplo de pergunta para Admin: "Qual foi o faturamento total em janeiro?" ou "Quantos clientes novos tivemos no último mês?".
    - Exemplo de pergunta para qualquer usuário: "Como eu faço para criar um novo cliente?".
    - Se o usuário perguntar como fazer algo que não está neste manual, diga que essa funcionalidade ainda não existe ou que você não tem essa informação.
    `;

    // 🚦 LÓGICA DE PERFIL
    if (isAdmin === true) {
      const supabase = createClient(supabaseUrl!, supabaseServiceKey!);

      // Busca todos os dados relevantes em paralelo para otimizar o tempo de resposta
      const [
        { data: orcamentos, error: orcamentosError },
        { data: clientes, error: clientesError },
        { data: usuarios, error: usuariosError }
      ] = await Promise.all([
        supabase.from('orcamentos').select('*'),
        supabase.from('clientes').select('*'),
        supabase.from('usuarios').select('*') // Seleciona apenas campos seguros
      ]);
      
      // Valida se houve erro em alguma das buscas
      if (orcamentosError) throw new Error(`Erro ao ler orçamentos: ${orcamentosError.message}`);
      if (clientesError) throw new Error(`Erro ao ler clientes: ${clientesError.message}`);
      if (usuariosError) throw new Error(`Erro ao ler usuários: ${usuariosError.message}`);
      
      // Constrói a string com os dados do banco para injetar no prompt
      dadosDoBanco = "";
      if (orcamentos) {
        dadosDoBanco += `\n\nDados de Orçamentos (usados para calcular faturamento):\n${JSON.stringify(orcamentos)}`;
      }
      if (clientes) {
        dadosDoBanco += `\n\nDados de Clientes:\n${JSON.stringify(clientes)}`;
      }
      if (usuarios) {
        dadosDoBanco += `\n\nDados de Usuários da Equipe:\n${JSON.stringify(usuarios)}`;
      }

      regrasDaIA = `Você é o assistente gerencial do aplicativo MinasLar. Hoje é dia ${dataHoje}. Você tem acesso total aos dados da empresa (orçamentos, clientes e equipe). Baseie-se APENAS nos dados fornecidos abaixo para responder.`;
      
    } else {
      const supabase = createClient(supabaseUrl!, supabaseServiceKey!);

      // Busca todos os dados relevantes em paralelo para otimizar o tempo de resposta
      const [
        { data: orcamentos, error: orcamentosError },
        { data: clientes, error: clientesError },
        { data: usuarios, error: usuariosError }
      ] = await Promise.all([
        supabase.from('orcamentos').select('id, user_id, cliente_id, titulo, descricao, data_pega, data_entrega, horario_do_dia, entregue, eh_retorno'), // Seleciona apenas campos seguros
        supabase.from('clientes').select('*'),
        supabase.from('usuarios').select('*') // Seleciona apenas campos seguros
      ]);
      
      // Valida se houve erro em alguma das buscas
      if (orcamentosError) throw new Error(`Erro ao ler orçamentos: ${orcamentosError.message}`);
      if (clientesError) throw new Error(`Erro ao ler clientes: ${clientesError.message}`);
      if (usuariosError) throw new Error(`Erro ao ler usuários: ${usuariosError.message}`);
      
      // Constrói a string com os dados do banco para injetar no prompt
      dadosDoBanco = "";
      if (orcamentos) {
        dadosDoBanco += `\n\nDados de Orçamentos (usados para calcular faturamento):\n${JSON.stringify(orcamentos)}`;
      }
      if (clientes) {
        dadosDoBanco += `\n\nDados de Clientes:\n${JSON.stringify(clientes)}`;
      }
      if (usuarios) {
        dadosDoBanco += `\n\nDados de Usuários da Equipe:\n${JSON.stringify(usuarios)}`;
      }      
      regrasDaIA = `Você é o assistente operacional do aplicativo MinasLar. Hoje é dia ${dataHoje}. Você NÃO tem acesso a dados financeiros. Se perguntarem de faturamento ou algo do genero, negue o acesso educadamente.`;
    }

    // 🧩 JUNTANDO TUDO: Regras + Manual + Dados + Pergunta
    const prompt = `${regrasDaIA}\n\n${manualDoApp}${dadosDoBanco}\n\nPergunta do usuário: ${pergunta}`;

    const result = await model.generateContent(prompt);
    const textoResposta = result.response.text();

    return new Response(
      JSON.stringify({ resposta: textoResposta }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error: any) {
    return new Response(JSON.stringify({ erro: error.message }), { status: 400, headers: corsHeaders })
  }
})