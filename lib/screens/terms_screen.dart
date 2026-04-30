import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Termos de Uso")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Termos de Uso - Meu Cozinheiro",
              style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildSection("1. Aceitação dos Termos", "Ao acessar e usar o aplicativo Meu Cozinheiro, você concorda em cumprir estes termos de serviço. Se você não concordar com algum destes termos, está proibido de usar ou acessar este aplicativo."),
            _buildSection("2. Uso de Inteligência Artificial", "O Meu Cozinheiro utiliza modelos de IA para extrair receitas de textos e vídeos. Embora busquemos a máxima precisão, não garantimos que todas as receitas geradas estejam livres de erros. Sempre revise os ingredientes e instruções antes de cozinhar."),
            _buildSection("3. Extração de Receitas e Direitos Autorais", "O Meu Cozinheiro extrai exclusivamente informações factuais de receitas — listas de ingredientes e instruções de preparo — de fontes públicas na internet. Receitas, enquanto procedimentos e fatos culinários, não constituem obras protegidas por direitos autorais conforme o Art. 8º da Lei nº 9.610/98 (Lei de Direitos Autorais do Brasil). O aplicativo não copia, armazena ou redistribui vídeos, fotografias, ilustrações ou textos criativos de terceiros. Todo conteúdo extraído é reformulado pela Inteligência Artificial em texto próprio, e a fonte original é sempre citada como referência."),
            _buildSection("4. Propriedade Intelectual de Terceiros", "Respeitamos a propriedade intelectual de criadores de conteúdo. Caso algum criador de conteúdo identifique que seu material protegido esteja sendo indevidamente reproduzido pelo aplicativo, poderá entrar em contato conosco para solicitar a remoção imediata do conteúdo. O uso do app para fins de republicação ou comercialização de receitas extraídas sem autorização do autor original é estritamente proibido."),
            _buildSection("5. Responsabilidade Nutricional", "O aplicativo não fornece aconselhamento médico ou nutricional. O uso das informações é por sua conta e risco. Pessoas com alergias alimentares ou restrições médicas devem consultar um profissional de saúde antes de preparar qualquer receita."),
            _buildSection("6. Cadastro e Segurança", "Você é responsável por manter a confidencialidade de sua senha e conta, sendo totalmente responsável por todas as atividades que ocorram sob sua senha ou conta."),
            _buildSection("7. Assinaturas e Compras", "O Meu Cozinheiro oferece compras dentro do aplicativo, incluindo pacotes de diamantes (créditos consumíveis) e assinaturas PRO (mensal e anual). Os pagamentos são processados exclusivamente pelo Google Play. Assinaturas são renovadas automaticamente a menos que o cancelamento seja realizado com pelo menos 24 horas de antecedência ao fim do período vigente. Diamantes adquiridos não expiram e não são reembolsáveis após o uso. Para solicitar reembolso de compras não utilizadas, entre em contato através do Google Play."),
            _buildSection("8. Anúncios e Vídeos Patrocinados", "Usuários não-PRO podem assistir a vídeos patrocinados para ganhar créditos (diamantes). Os anúncios são fornecidos pelo Google AdMob. A disponibilidade e o conteúdo dos anúncios são de responsabilidade do Google e podem variar conforme a região e o perfil do usuário."),
            _buildSection("9. Limitação de Responsabilidade", "O Meu Cozinheiro é fornecido \"como está\". Não garantimos disponibilidade ininterrupta do serviço, precisão absoluta das receitas extraídas, ou a disponibilidade de anúncios em todas as regiões. Em nenhuma circunstância seremos responsáveis por danos indiretos, incidentais ou consequenciais decorrentes do uso do aplicativo."),
            _buildSection("10. Alterações nos Termos", "Reservamo-nos o direito de modificar estes termos a qualquer momento. O uso contínuo do app após alterações constitui aceitação dos novos termos. Alterações significativas serão comunicadas através do próprio aplicativo."),
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
