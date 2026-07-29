#!/usr/bin/env python3
"""
AUREUS FinOps - Cost Report Generator
Gera relatórios de custos e otimizações para a plataforma AUREUS
"""

import json
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime, timedelta
import os

class CostReportGenerator:
    def __init__(self):
        self.report_data = {}
        self.optimization_recommendations = []
        
    def load_cost_data(self, cost_file):
        """Carrega dados de custos do AWS Cost Explorer"""
        with open(cost_file, 'r') as f:
            self.cost_data = json.load(f)
    
    def load_optimization_data(self, optimization_file):
        """Carrega dados de otimização"""
        with open(optimization_file, 'r') as f:
            self.optimization_data = json.load(f)
    
    def analyze_costs_by_service(self):
        """Analisa custos por serviço"""
        services = {}
        
        for result in self.cost_data['ResultsByTime']:
            for group in result['Groups']:
                service = group['Keys'][0]
                cost = float(group['Metrics']['BlendedCost']['Amount'])
                
                if service not in services:
                    services[service] = 0
                services[service] += cost
        
        return services
    
    def analyze_cost_trends(self):
        """Analisa tendências de custos"""
        trends = []
        
        for result in self.cost_data['ResultsByTime']:
            date = result['TimePeriod']['Start']
            total_cost = sum(
                float(group['Metrics']['BlendedCost']['Amount'])
                for group in result['Groups']
            )
            trends.append({
                'date': date,
                'cost': total_cost
            })
        
        return trends
    
    def analyze_optimization_opportunities(self):
        """Analisa oportunidades de otimização"""
        opportunities = []
        
        # EC2 Recommendations
        if 'ec2-recommendations.json' in os.listdir('.'):
            with open('ec2-recommendations.json', 'r') as f:
                ec2_data = json.load(f)
                
            for rec in ec2_data.get('instanceRecommendations', []):
                opportunity = {
                    'type': 'EC2 Instance',
                    'resource_id': rec.get('instanceId', 'N/A'),
                    'current_type': rec.get('currentInstanceType', 'N/A'),
                    'recommended_type': rec.get('recommendedInstanceType', 'N/A'),
                    'savings': rec.get('savingsOpportunity', {}).get('estimatedMonthlySavings', {}).get('value', 0),
                    'confidence': rec.get('recommendationSource', 'N/A')
                }
                opportunities.append(opportunity)
        
        # EBS Recommendations
        if 'ebs-recommendations.json' in os.listdir('.'):
            with open('ebs-recommendations.json', 'r') as f:
                ebs_data = json.load(f)
                
            for rec in ebs_data.get('volumeRecommendations', []):
                opportunity = {
                    'type': 'EBS Volume',
                    'resource_id': rec.get('volumeArn', 'N/A'),
                    'current_type': rec.get('currentConfiguration', {}).get('volumeType', 'N/A'),
                    'recommended_type': rec.get('recommendedConfiguration', {}).get('volumeType', 'N/A'),
                    'savings': rec.get('savingsOpportunity', {}).get('estimatedMonthlySavings', {}).get('value', 0),
                    'confidence': rec.get('recommendationSource', 'N/A')
                }
                opportunities.append(opportunity)
        
        return opportunities
    
    def generate_cost_visualizations(self):
        """Gera visualizações de custos"""
        # Configurar estilo
        plt.style.use('seaborn-v0_8')
        sns.set_palette("husl")
        
        # 1. Custos por Serviço
        services = self.analyze_costs_by_service()
        if services:
            plt.figure(figsize=(12, 8))
            services_df = pd.DataFrame(list(services.items()), columns=['Service', 'Cost'])
            services_df = services_df.sort_values('Cost', ascending=False)
            
            plt.subplot(2, 2, 1)
            plt.pie(services_df['Cost'], labels=services_df['Service'], autopct='%1.1f%%')
            plt.title('Custos por Serviço')
            
            plt.subplot(2, 2, 2)
            plt.bar(services_df['Service'], services_df['Cost'])
            plt.title('Custos por Serviço (Bar Chart)')
            plt.xticks(rotation=45)
        
        # 2. Tendências de Custos
        trends = self.analyze_cost_trends()
        if trends:
            trends_df = pd.DataFrame(trends)
            trends_df['date'] = pd.to_datetime(trends_df['date'])
            
            plt.subplot(2, 2, 3)
            plt.plot(trends_df['date'], trends_df['cost'], marker='o')
            plt.title('Tendência de Custos ao Longo do Tempo')
            plt.xlabel('Data')
            plt.ylabel('Custo (USD)')
            plt.xticks(rotation=45)
        
        # 3. Oportunidades de Otimização
        opportunities = self.analyze_optimization_opportunities()
        if opportunities:
            opp_df = pd.DataFrame(opportunities)
            
            plt.subplot(2, 2, 4)
            opp_df['savings'] = pd.to_numeric(opp_df['savings'], errors='coerce')
            opp_df = opp_df.dropna(subset=['savings'])
            
            if not opp_df.empty:
                plt.bar(opp_df['type'], opp_df['savings'])
                plt.title('Economias Potenciais por Tipo de Recurso')
                plt.ylabel('Economia Mensal (USD)')
                plt.xticks(rotation=45)
        
        plt.tight_layout()
        plt.savefig('cost-analysis.png', dpi=300, bbox_inches='tight')
        plt.close()
    
    def generate_html_report(self):
        """Gera relatório HTML"""
        html_content = f"""
        <!DOCTYPE html>
        <html lang="pt-BR">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>AUREUS FinOps - Relatório de Custos</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 20px; }}
                .header {{ background-color: #1976d2; color: white; padding: 20px; border-radius: 8px; }}
                .section {{ margin: 20px 0; padding: 20px; border: 1px solid #ddd; border-radius: 8px; }}
                .metric {{ display: inline-block; margin: 10px; padding: 15px; background-color: #f5f5f5; border-radius: 5px; }}
                .metric-value {{ font-size: 24px; font-weight: bold; color: #1976d2; }}
                .metric-label {{ font-size: 14px; color: #666; }}
                .recommendation {{ background-color: #e8f5e8; padding: 15px; margin: 10px 0; border-left: 4px solid #4caf50; }}
                .warning {{ background-color: #fff3cd; padding: 15px; margin: 10px 0; border-left: 4px solid #ffc107; }}
                .error {{ background-color: #f8d7da; padding: 15px; margin: 10px 0; border-left: 4px solid #dc3545; }}
                table {{ width: 100%; border-collapse: collapse; margin: 20px 0; }}
                th, td {{ border: 1px solid #ddd; padding: 12px; text-align: left; }}
                th {{ background-color: #f2f2f2; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h1>🏛️ AUREUS FinOps - Relatório de Custos</h1>
                <p>Relatório gerado em: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}</p>
            </div>
            
            <div class="section">
                <h2>📊 Resumo Executivo</h2>
                <div class="metric">
                    <div class="metric-value">${sum(self.analyze_costs_by_service().values()):,.2f}</div>
                    <div class="metric-label">Custo Total Mensal</div>
                </div>
                <div class="metric">
                    <div class="metric-value">{len(self.analyze_optimization_opportunities())}</div>
                    <div class="metric-label">Oportunidades de Otimização</div>
                </div>
                <div class="metric">
                    <div class="metric-value">${sum(opp['savings'] for opp in self.analyze_optimization_opportunities() if isinstance(opp['savings'], (int, float))):,.2f}</div>
                    <div class="metric-label">Economia Potencial Mensal</div>
                </div>
            </div>
            
            <div class="section">
                <h2>💰 Custos por Serviço</h2>
                <table>
                    <tr><th>Serviço</th><th>Custo Mensal (USD)</th><th>% do Total</th></tr>
        """
        
        services = self.analyze_costs_by_service()
        total_cost = sum(services.values())
        
        for service, cost in sorted(services.items(), key=lambda x: x[1], reverse=True):
            percentage = (cost / total_cost) * 100
            html_content += f"<tr><td>{service}</td><td>${cost:,.2f}</td><td>{percentage:.1f}%</td></tr>"
        
        html_content += """
                </table>
            </div>
            
            <div class="section">
                <h2>🎯 Oportunidades de Otimização</h2>
        """
        
        opportunities = self.analyze_optimization_opportunities()
        for opp in opportunities:
            if isinstance(opp['savings'], (int, float)) and opp['savings'] > 0:
                html_content += f"""
                <div class="recommendation">
                    <h4>{opp['type']} - {opp['resource_id']}</h4>
                    <p><strong>Atual:</strong> {opp['current_type']}</p>
                    <p><strong>Recomendado:</strong> {opp['recommended_type']}</p>
                    <p><strong>Economia Potencial:</strong> ${opp['savings']:,.2f}/mês</p>
                    <p><strong>Confiança:</strong> {opp['confidence']}</p>
                </div>
                """
        
        html_content += """
            </div>
            
            <div class="section">
                <h2>📈 Análise de Tendências</h2>
                <p>As tendências de custos mostram a evolução dos gastos ao longo do tempo.</p>
                <img src="cost-analysis.png" alt="Análise de Custos" style="width: 100%; max-width: 800px;">
            </div>
            
            <div class="section">
                <h2>🔧 Recomendações de Ação</h2>
                <div class="recommendation">
                    <h4>1. Otimização de Instâncias EC2</h4>
                    <p>Revise as recomendações de redimensionamento de instâncias EC2 para reduzir custos.</p>
                </div>
                <div class="recommendation">
                    <h4>2. Análise de Volumes EBS</h4>
                    <p>Considere migrar volumes EBS para tipos mais econômicos quando apropriado.</p>
                </div>
                <div class="recommendation">
                    <h4>3. Implementação de Savings Plans</h4>
                    <p>Avalie a implementação de Savings Plans para compromissos de longo prazo.</p>
                </div>
                <div class="recommendation">
                    <h4>4. Monitoramento Contínuo</h4>
                    <p>Implemente alertas de custo para monitorar gastos em tempo real.</p>
                </div>
            </div>
            
            <div class="section">
                <h2>📋 Próximos Passos</h2>
                <ol>
                    <li>Revisar e implementar recomendações de otimização</li>
                    <li>Configurar alertas de custo no AWS Budgets</li>
                    <li>Implementar tags de custo para melhor rastreabilidade</li>
                    <li>Agendar revisão mensal de custos</li>
                    <li>Considerar migração para instâncias Spot quando apropriado</li>
                </ol>
            </div>
        </body>
        </html>
        """
        
        with open('cost-report.html', 'w', encoding='utf-8') as f:
            f.write(html_content)
    
    def generate_report(self):
        """Gera relatório completo"""
        print("Gerando relatório de custos...")
        
        # Carregar dados
        if 'cost-analysis.json' in os.listdir('.'):
            self.load_cost_data('cost-analysis.json')
        
        # Gerar visualizações
        self.generate_cost_visualizations()
        
        # Gerar relatório HTML
        self.generate_html_report()
        
        print("Relatório gerado com sucesso: cost-report.html")

if __name__ == "__main__":
    generator = CostReportGenerator()
    generator.generate_report()
