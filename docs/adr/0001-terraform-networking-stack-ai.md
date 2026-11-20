# ADR 0001: Nova stack Terraform de rede `01-networking-stack-ai`

## Status
Proposto

## Contexto
O projeto precisa de uma nova stack Terraform de rede, separada da stack de workshop existente, com o diretorio `01-networking-stack-ai` e arquivos `*.tf` organizados por responsabilidade. A stack deve criar uma VPC em AWS usando boas praticas basicas de Terraform, provider AWS configurado, tags padrao, subnets publicas e privadas, internet gateway e tabelas de rota.

A regiao alvo assumida e `us-east-1` (N. Virginia), pois foi definida anteriormente como preferencia operacional do projeto.

## Requisitos
- Criar o diretorio `01-networking-stack-ai`.
- Criar arquivos Terraform separados por responsabilidade.
- Configurar o provider AWS.
- Provisionar uma VPC nova, sem tocar na VPC default.
- Criar subnets publicas e privadas em pelo menos 2 Availability Zones.
- Criar internet gateway para subnets publicas.
- Criar route table publica com rota `0.0.0.0/0` para o internet gateway.
- Associar subnets publicas a route table publica.
- Criar route table privada sem NAT Gateway nesta primeira versao.
- Expor outputs uteis para integracao futura.
- Manter valores editaveis por variaveis.

## Premissas
- Ambiente inicial: `dev`.
- Regiao: `us-east-1`.
- CIDR da VPC: `10.10.0.0/16`.
- Subnets publicas:
  - `10.10.1.0/24`
  - `10.10.2.0/24`
- Subnets privadas:
  - `10.10.101.0/24`
  - `10.10.102.0/24`
- NAT Gateway nao sera criado inicialmente para evitar custo recorrente.
- Backend remoto nao sera configurado nesta primeira entrega; state local sera aceito para laboratorio.
- `.terraform.lock.hcl` deve ser versionado depois de `terraform init`.
- Arquivos sensiveis como `.env`, `.tfvars` reais e `terraform.tfstate` nao devem ser versionados.

## Decisao
Criar uma stack Terraform independente em `01-networking-stack-ai`, usando provider `hashicorp/aws` versao `~> 6.0`, com recursos AWS de rede basicos:

- `aws_vpc`
- `aws_subnet`
- `aws_internet_gateway`
- `aws_route_table`
- `aws_route_table_association`

A implementacao deve evitar NAT Gateway nesta fase. Caso subnets privadas precisem de saida para internet no futuro, um ADR separado deve decidir entre NAT Gateway, NAT Instance, VPC Endpoints ou manter isolamento total.

## Alternativas consideradas

### Alternativa A: VPC minima apenas com subnets publicas
Mais simples e barata, mas limita evolucao para workloads privados.

### Alternativa B: VPC completa com publicas, privadas e NAT Gateway
Mais proxima de producao, mas gera custo recorrente de NAT Gateway e transferencia de dados. Nao e adequada para laboratorio inicial sem necessidade clara.

### Alternativa C: VPC com publicas, privadas, sem NAT Gateway
Escolhida. Permite boa separacao de rede, baixo custo inicial e evolucao posterior por ADR.

## Justificativa
A alternativa C equilibra organizacao, aprendizado e custo. Ela cria uma base de rede mais realista que uma VPC minima, mas evita custos recorrentes desnecessarios. A separacao em arquivos facilita manutencao por outro agente e reduz risco de mudancas acidentais.

## Arquitetura proposta

Diretorio esperado:

```text
01-networking-stack-ai/
  main.tf
  variables.tf
  locals.tf
  vpc.tf
  subnets.tf
  routes.tf
  outputs.tf
  versions.tf
```

Responsabilidades:

- `versions.tf`: versao minima do Terraform e provider AWS.
- `main.tf`: configuracao do provider AWS.
- `variables.tf`: variaveis de entrada da stack.
- `locals.tf`: padroes de nomenclatura e tags.
- `vpc.tf`: VPC e internet gateway.
- `subnets.tf`: subnets publicas e privadas.
- `routes.tf`: route tables e associacoes.
- `outputs.tf`: ids da VPC, subnets, route tables e internet gateway.

Recursos esperados:

```text
aws_vpc.main
aws_internet_gateway.main
aws_subnet.public[*]
aws_subnet.private[*]
aws_route_table.public
aws_route_table.private
aws_route_table_association.public[*]
aws_route_table_association.private[*]
```

## Seguranca
- A stack nao deve criar security groups permissivos.
- A stack nao deve criar instancias EC2 ou workloads.
- Subnets privadas nao devem receber IP publico no launch.
- Subnets publicas podem habilitar `map_public_ip_on_launch = true`.
- Tags devem identificar projeto, ambiente e gerenciamento por Terraform.
- Nenhuma credencial deve ser escrita em Terraform.
- `.env`, `*.tfvars` sensiveis e states devem permanecer ignorados.

## Custos e FinOps
Recursos desta fase tendem a nao gerar custo relevante por si so:

- VPC: sem custo direto.
- Subnets: sem custo direto.
- Internet Gateway: sem custo direto enquanto nao houver trafego cobrado.
- Route Tables: sem custo direto.

Nao criar nesta fase:

- NAT Gateway, pois gera custo por hora e por GB processado.
- VPC Endpoints, pois alguns podem gerar custo por hora.
- Flow Logs, pois CloudWatch Logs/S3 podem gerar custo.

## Operacao e observabilidade
- Nao habilitar VPC Flow Logs nesta primeira versao.
- Caso a stack evolua para ambiente produtivo, criar ADR especifico para:
  - VPC Flow Logs;
  - metricas e alarmes;
  - centralizacao de logs;
  - deteccao de trafego anomalo.

## Riscos
- Sem NAT Gateway, recursos em subnets privadas nao terao saida direta para internet.
- Sem backend remoto, o state local pode gerar conflito se mais de uma pessoa aplicar a stack.
- CIDR `10.10.0.0/16` pode conflitar com redes existentes se houver VPN, peering ou Transit Gateway no futuro.
- `terraform apply` criara recursos reais na conta AWS e exige aprovacao humana.

## Consequencias
- O projeto passa a ter uma stack de rede mais adequada para evolucao.
- O custo inicial permanece baixo.
- Futuras stacks de compute, banco ou containers poderao consumir outputs desta stack.
- Um futuro ADR deve tratar backend remoto antes de uso colaborativo ou ambiente produtivo.

## Plano de implementacao para o DevOps Engineer Agent

1. Confirmar conta e regiao antes de implementar:

```bash
aws sts get-caller-identity
aws configure get region
```

2. Criar o diretorio:

```text
01-networking-stack-ai/
```

3. Criar `versions.tf` com:
- `required_version >= 1.6.0`;
- provider `hashicorp/aws ~> 6.0`.

4. Criar `variables.tf` com:
- `aws_region`;
- `project_name`;
- `environment`;
- `vpc_cidr`;
- `public_subnet_cidrs`;
- `private_subnet_cidrs`;
- `availability_zones`;
- `default_tags`.

5. Criar `locals.tf` com:
- `name_prefix`;
- merge de tags padrao;
- tags comuns.

6. Criar `main.tf` com provider AWS:
- `region = var.aws_region`;
- `default_tags`.

7. Criar `vpc.tf` com:
- `aws_vpc.main`;
- `aws_internet_gateway.main`.

8. Criar `subnets.tf` com:
- `aws_subnet.public`;
- `aws_subnet.private`;
- uso de `for_each` ou `count` consistente.

9. Criar `routes.tf` com:
- `aws_route_table.public`;
- rota default publica para internet gateway;
- `aws_route_table.private`;
- associacoes publicas e privadas.

10. Criar `outputs.tf` com:
- `vpc_id`;
- `vpc_cidr_block`;
- `public_subnet_ids`;
- `private_subnet_ids`;
- `internet_gateway_id`;
- `public_route_table_id`;
- `private_route_table_id`.

11. Executar validacoes:

```bash
terraform fmt -recursive
cd 01-networking-stack-ai
terraform init
terraform validate
terraform plan
```

12. Nao executar `terraform apply` sem aprovacao humana explicita.

## Arquivos esperados

```text
01-networking-stack-ai/versions.tf
01-networking-stack-ai/main.tf
01-networking-stack-ai/variables.tf
01-networking-stack-ai/locals.tf
01-networking-stack-ai/vpc.tf
01-networking-stack-ai/subnets.tf
01-networking-stack-ai/routes.tf
01-networking-stack-ai/outputs.tf
```

## Recursos AWS/Terraform envolvidos
- `aws_vpc`
- `aws_subnet`
- `aws_internet_gateway`
- `aws_route_table`
- `aws_route_table_association`

## Criterios de aceite
- O diretorio `01-networking-stack-ai` existe.
- Todos os arquivos esperados existem.
- `terraform fmt -recursive` nao deixa diffs pendentes.
- `terraform init` conclui com sucesso.
- `terraform validate` conclui com sucesso.
- `terraform plan` mostra somente criacao dos recursos planejados.
- O plano nao mostra destruicao de recursos.
- O plano nao altera a VPC default existente.
- Nenhum segredo ou state Terraform e versionado.
- `.terraform.lock.hcl` e gerado e pode ser versionado.

## Validacoes obrigatorias

Antes de qualquer `apply`, o DevOps Engineer Agent deve reportar:

```text
Conta AWS alvo
Regiao alvo
Resumo do terraform plan
Recursos pagos envolvidos
Recursos a criar
Recursos a alterar
Recursos a destruir
```

`terraform apply` exige aprovacao humana explicita.

## Consultas MCP realizadas
- Terraform MCP `get_latest_provider_version` para `hashicorp/aws`: retornou `6.46.0`.
- Terraform MCP `search_providers` para `aws_vpc` no provider `hashicorp/aws` versao `6.46.0`: recurso `vpc` encontrado.
- Terraform MCP `search_providers` para `aws_subnet` no provider `hashicorp/aws` versao `6.46.0`: recurso `subnet` encontrado.
- Terraform MCP `search_providers` para route tables no provider `hashicorp/aws` versao `6.46.0`: recursos `route_table` e `route_table_association` encontrados.
- AWS MCP `get_regional_availability` em `us-east-1`: `AWS::EC2::VPC`, `AWS::EC2::Subnet`, `AWS::EC2::InternetGateway`, `AWS::EC2::RouteTable` e `AWS::EC2::NatGateway` disponiveis.

## O que NAO deve ser feito
- Nao executar `terraform apply` automaticamente.
- Nao criar NAT Gateway nesta fase.
- Nao criar EC2, RDS, ECS, EKS ou workloads.
- Nao apagar ou alterar VPC default.
- Nao commitar `.env`, `*.tfvars` sensiveis, `.terraform/` ou `terraform.tfstate`.
- Nao configurar backend remoto sem novo ADR ou aprovacao explicita.
