import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacidade")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Política de Privacidade",
              style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildSection("1. Coleta de Dados", "Coletamos informações como nome, e-mail, idade e gênero para personalizar sua experiência culinária e gerenciar sua conta de forma segura via Firebase Auth. Não coletamos dados sensíveis como localização, contatos ou informações financeiras diretamente."),
            _buildSection("2. Uso das Informações", "Seus dados de despensa e receitas favoritas são armazenados no Firestore e são de acesso exclusivo seu. Não vendemos, compartilhamos ou distribuímos suas informações pessoais para terceiros."),
            _buildSection("3. Processamento de Receitas por IA", "Quando você utiliza a função de extração de receitas, o conteúdo público fornecido (URL ou texto colado) é enviado temporariamente para os servidores de IA do Google (Gemini API) para processamento. Nenhum dado pessoal seu é enviado junto — apenas o conteúdo da receita. O Google não armazena essas requisições para fins de treinamento quando usadas via API."),
            _buildSection("4. Anúncios e Analytics", "Utilizamos o Google AdMob para exibir vídeos patrocinados. O AdMob pode coletar identificadores de publicidade anônimos (GAID/IDFA) para personalizar anúncios. Você pode redefinir ou desativar esse identificador nas configurações do seu dispositivo. Também utilizamos identificadores anônimos para melhorar nossos algoritmos de sugestão de receitas baseados em seus hábitos, mas essas informações não são vinculadas à sua identidade fora do contexto do app."),
            _buildSection("5. Compras e Dados Financeiros", "Todas as transações financeiras (compra de diamantes e assinaturas PRO) são processadas exclusivamente pelo Google Play. O Meu Cozinheiro não tem acesso a dados de cartão de crédito, conta bancária ou qualquer informação financeira. Armazenamos apenas o registro de créditos (diamantes) e status da assinatura na sua conta."),
            _buildSection("6. Segurança", "Implementamos medidas de segurança robustas para proteger seus dados pessoais. O acesso aos dados é criptografado via HTTPS/TLS e segue os padrões de segurança do Google Cloud (Firebase). As senhas são gerenciadas pelo Firebase Auth com hashing seguro e nunca são armazenadas em texto plano."),
            _buildSection("7. Seus Direitos (LGPD)", "Em conformidade com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018), você tem o direito de: acessar todos os dados pessoais que mantemos sobre você; corrigir dados incompletos ou incorretos; solicitar a exclusão completa de seus dados e conta; revogar o consentimento para o uso de dados a qualquer momento; e exportar seus dados em formato legível. Para exercer qualquer desses direitos, acesse as Configurações do aplicativo ou entre em contato conosco."),
            _buildSection("8. Retenção de Dados", "Seus dados são mantidos enquanto sua conta estiver ativa. Ao excluir sua conta, todos os dados pessoais, receitas e itens de despensa são permanentemente removidos dos nossos servidores em até 30 dias."),
            _buildSection("9. Menores de Idade", "O Meu Cozinheiro não é direcionado a menores de 13 anos. Não coletamos intencionalmente dados de crianças. Se tomarmos conhecimento de que dados de um menor foram coletados, procederemos com a exclusão imediata."),
            _buildSection("10. Contato", "Para questões relacionadas à privacidade, entre em contato pelo e-mail: suporte@meucozinheiro.app"),
            const SizedBox(height: 20),
            Text("Última atualização: Abril de 2026", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFFC84C2C))),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF262321))),
        ],
      ),
    );
  }
}
