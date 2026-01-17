# 📑 Índice Completo do Repositório

## 🎯 Início Rápido

Para começar rapidamente, leia nesta ordem:

1. **[README.md](README.md)** - Visão geral e quick start (10 min)
2. **[QUICKSTART.sh](QUICKSTART.sh)** - Referência visual (5 min)
3. **[envs/dev/README.md](envs/dev/README.md)** - Como executar (5 min)
4. Escolha uma abordagem:
   - **Simples:** `make plan-dev && make apply-dev` (1 hora)
   - **Detalhada:** Seguir [QUICKSTART.sh](QUICKSTART.sh) (2 horas)

---

## 📚 Documentação Completa

### 📋 Visão Geral
| Arquivo | Descrição | Tempo |
|---------|-----------|-------|
| [README.md](README.md) | Documentação principal do projeto | 10 min |
| [QUICKSTART.sh](QUICKSTART.sh) | Referência visual de setup | 5 min |
| [DELIVERY.md](DELIVERY.md) | Resumo da entrega completa | 5 min |
| [INDEX.md](INDEX.md) | Este arquivo - navegação | 2 min |

### 🏗️ Architecture Decision Records (ADRs)
| ADR | Título | Leitura |
|-----|--------|---------|
| [ADR-0001](docs/decisions/ADR-0001-backend-state.md) | Backend State (S3 + DynamoDB) | 10 min |
| [ADR-0002](docs/decisions/ADR-0002-naming-tags.md) | Naming Convention & Tags | 5 min |
| [ADR-0003](docs/decisions/ADR-0003-environments.md) | Multi-Environment Strategy | 5 min |

### 🔧 Operational Guides
| Runbook | Cenários | Leitura |
|---------|----------|---------|
| [troubleshooting.md](docs/runbooks/troubleshooting.md) | 8 problemas + soluções | 15 min |
| [EXTENDING.md](docs/EXTENDING.md) | Adicionar novos stacks | 10 min |

### 📁 Environment Guides
| Ambiente | Descrição | Arquivo |
|----------|-----------|---------|
| Development | Como usar dev | [envs/dev/README.md](envs/dev/README.md) |
| Production | Como usar prod + approvals | [envs/prod/README.md](envs/prod/README.md) |

---

## 🏗️ Stacks & Código

### Stack 1: Bootstrap
Cria infraestrutura para gerenciar state do Terraform

| Arquivo | Conteúdo | Linhas |
|---------|----------|--------|
| [stacks/bootstrap/versions.tf](stacks/bootstrap/versions.tf) | Terraform >= 1.6, AWS ~> 5.0 | 11 |
| [stacks/bootstrap/providers.tf](stacks/bootstrap/providers.tf) | AWS provider com assume_role | 14 |
| [stacks/bootstrap/locals.tf](stacks/bootstrap/locals.tf) | Naming pattern + default_tags | 12 |
| [stacks/bootstrap/variables.tf](stacks/bootstrap/variables.tf) | 12 variáveis com validação | 72 |
| [stacks/bootstrap/main.tf](stacks/bootstrap/main.tf) | S3 + DynamoDB + policies | 125 |
| [stacks/bootstrap/outputs.tf](stacks/bootstrap/outputs.tf) | 4 outputs úteis | 18 |

**Resources criados:**
- S3 bucket (versioning, encryption, public access block)
- DynamoDB lock table
- S3 bucket policy (deny DeleteBucket)
- S3 lifecycle (expire noncurrent versions)

**Run:**
```bash
cd stacks/bootstrap
terraform init
terraform plan -var-file=../../envs/dev/bootstrap.tfvars
terraform apply -var-file=../../envs/dev/bootstrap.tfvars
```

---

### Stack 2: Network
Cria VPC foundation com subnets, NAT, endpoints

| Arquivo | Conteúdo | Linhas |
|---------|----------|--------|
| [stacks/network/versions.tf](stacks/network/versions.tf) | Terraform >= 1.6, AWS ~> 5.0 | 11 |
| [stacks/network/providers.tf](stacks/network/providers.tf) | AWS provider com assume_role | 14 |
| [stacks/network/locals.tf](stacks/network/locals.tf) | Naming pattern + default_tags | 12 |
| [stacks/network/variables.tf](stacks/network/variables.tf) | 15 variáveis com validação | 120 |
| [stacks/network/main.tf](stacks/network/main.tf) | terraform-aws-modules/vpc + Flow Logs | 95 |
| [stacks/network/outputs.tf](stacks/network/outputs.tf) | 9 outputs importantes | 41 |

**Resources criados:**
- VPC com CIDR customizável
- Public subnets (3 AZs)
- Private subnets (3 AZs)
- NAT Gateway (single or per-AZ)
- Internet Gateway
- VPC endpoints (S3, DynamoDB)
- VPC Flow Logs (opcional)

**Run:**
```bash
cd stacks/network
terraform init -backend-config=../../envs/dev/network.backend.hcl
terraform plan -var-file=../../envs/dev/network.tfvars
terraform apply -var-file=../../envs/dev/network.tfvars
```

---

## ⚙️ Configuração de Ambientes

### Dev Environment
| Arquivo | Tipo | Conteúdo |
|---------|------|----------|
| [envs/dev/bootstrap.tfvars](envs/dev/bootstrap.tfvars) | Vars | Client, project, environment settings |
| [envs/dev/network.tfvars](envs/dev/network.tfvars) | Vars | VPC config (single NAT, no Flow Logs) |
| [envs/dev/bootstrap.backend.hcl](envs/dev/bootstrap.backend.hcl) | Backend | Init config |
| [envs/dev/network.backend.hcl](envs/dev/network.backend.hcl) | Backend | Init config |
| [envs/dev/README.md](envs/dev/README.md) | Guide | Como usar dev |

### Prod Environment
| Arquivo | Tipo | Conteúdo |
|---------|------|----------|
| [envs/prod/bootstrap.tfvars](envs/prod/bootstrap.tfvars) | Vars | Client, project, environment settings |
| [envs/prod/network.tfvars](envs/prod/network.tfvars) | Vars | VPC config (HA NAT, Flow Logs 30d) |
| [envs/prod/bootstrap.backend.hcl](envs/prod/bootstrap.backend.hcl) | Backend | Init config |
| [envs/prod/network.backend.hcl](envs/prod/network.backend.hcl) | Backend | Init config |
| [envs/prod/README.md](envs/prod/README.md) | Guide | Como usar prod + approvals |

---

## 🛠️ Ferramentas & Automação

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| [Makefile](Makefile) | Automation | 30+ targets para plan/apply/destroy |
| [.pre-commit-config.yaml](.pre-commit-config.yaml) | Git hooks | terraform_fmt, validate, tflint, tfsec |
| [.tflint.hcl](.tflint.hcl) | Linting | AWS + Terraform rules |
| [.gitignore](.gitignore) | VCS | .terraform/, *.tfstate, *.pem, etc |
| [scripts/check.sh](scripts/check.sh) | Script | Format, validate, lint checks |
| [scripts/init.sh](scripts/init.sh) | Script | Interactive environment setup |

### Makefile Targets
```
Validation:
  make validate              # Format + validate + lint
  make fmt                   # Auto-format files
  make lint                  # Run tflint
  make security              # Run tfsec

Planning & Applying:
  make plan-dev              # Plan dev bootstrap + network
  make apply-dev             # Apply dev
  make destroy-dev           # Destroy dev

  make plan-prod             # Plan prod
  make apply-prod            # Apply prod (with confirmation)
  make destroy-prod          # Destroy prod

Utilities:
  make output-dev            # Show dev outputs
  make state-list-dev        # List state resources
  make clean                 # Remove .terraform/ and *.tfplan
  make info                  # Show environment info
```

---

## 📊 Project Statistics

```
Arquivos criados:      44
Linhas de código:      ~2500
Stacks:                2 (bootstrap, network)
Ambientes:             2 (dev, prod)
ADRs:                  3
Runbooks:              1
Makefile targets:      30+
Pre-commit hooks:      4
```

---

## 🎓 Learning Path

### Nível 1: Entender
1. Ler [README.md](README.md)
2. Ler [QUICKSTART.sh](QUICKSTART.sh)
3. Ler [ADR-0001](docs/decisions/ADR-0001-backend-state.md)
4. Executar `make validate`

### Nível 2: Usar
1. Ler [envs/dev/README.md](envs/dev/README.md)
2. Executar `make plan-dev`
3. Executar `make apply-dev`
4. Verificar `make output-dev`

### Nível 3: Customizar
1. Editar `envs/*/bootstrap.tfvars`
2. Editar `envs/*/network.tfvars`
3. Executar `make plan-prod`
4. Ler [ADR-0002](docs/decisions/ADR-0002-naming-tags.md)

### Nível 4: Estender
1. Ler [docs/EXTENDING.md](docs/EXTENDING.md)
2. Criar novo stack em `stacks/my-stack/`
3. Adicionar variáveis em `envs/*/my-stack.tfvars`
4. Ler [ADR-0003](docs/decisions/ADR-0003-environments.md)

### Nível 5: Troubleshoot
1. Ler [docs/runbooks/troubleshooting.md](docs/runbooks/troubleshooting.md)
2. Procurar seu cenário
3. Seguir as soluções

---

## 🔍 Procurando por algo?

### Por Tipo
- **Terraform code:** `stacks/bootstrap/` `stacks/network/`
- **Variables:** `stacks/*/variables.tf` `envs/*/*tfvars`
- **Documentation:** `docs/decisions/` `docs/runbooks/`
- **Automation:** `Makefile` `.pre-commit-config.yaml` `scripts/`

### Por Tópico
- **State management:** [ADR-0001](docs/decisions/ADR-0001-backend-state.md), [stacks/bootstrap/main.tf](stacks/bootstrap/main.tf)
- **Naming & tags:** [ADR-0002](docs/decisions/ADR-0002-naming-tags.md), [stacks/*/locals.tf](stacks/bootstrap/locals.tf)
- **Multi-environment:** [ADR-0003](docs/decisions/ADR-0003-environments.md), [envs/](envs/)
- **Network:** [stacks/network/main.tf](stacks/network/main.tf), [stacks/network/variables.tf](stacks/network/variables.tf)
- **Security:** [ADR-0001](docs/decisions/ADR-0001-backend-state.md), [README.md#security](README.md)
- **Troubleshooting:** [docs/runbooks/troubleshooting.md](docs/runbooks/troubleshooting.md)

### Por Comando
- **Deploy:** `make apply-dev` ou [envs/dev/README.md](envs/dev/README.md)
- **Validar:** `make validate`
- **Ver saída:** `make output-dev`
- **Troubleshoot:** [docs/runbooks/troubleshooting.md](docs/runbooks/troubleshooting.md)
- **Estender:** [docs/EXTENDING.md](docs/EXTENDING.md)

---

## 🚀 Quicklinks

```bash
# Começar
make help                              # Ver todos os targets
make validate                          # Testar setup
make plan-dev                          # Planejar dev
make apply-dev                         # Deploy dev

# Customizar para cliente
vim envs/dev/bootstrap.tfvars
vim envs/dev/network.tfvars

# Troubleshoot
cat docs/runbooks/troubleshooting.md

# Estender
cat docs/EXTENDING.md
mkdir -p stacks/my-new-stack
```

---

## 📞 Contatos & Escalations

Referências rápidas:

- **Problemas com state:** Ver [troubleshooting.md](docs/runbooks/troubleshooting.md) seção 1-4
- **Questões de design:** Ver os 3 ADRs em [docs/decisions/](docs/decisions/)
- **Howto adicionar recursos:** Ver [docs/EXTENDING.md](docs/EXTENDING.md)
- **Referência de código:** Ver stacks respectivos em [stacks/](stacks/)

---

## ✅ Checklist para Novo Cliente

```bash
# 1. Clone template
git clone <repo-url>
cd aws-terraform

# 2. Customize
sed -i 's/acme/customer/g' envs/**/*.tfvars
vim envs/dev/bootstrap.tfvars

# 3. Validate
make validate

# 4. Deploy
make plan-dev
make apply-dev

# 5. Verify
make output-dev
aws s3 ls  # Verificar bucket criado

# 6. Document
git log --oneline
git commit -am "Bootstrap: Initial setup for <customer>"

# 7. Share
git push origin main
git branch -m main <customer>-main
```

---

**Última atualização:** 2026-01-17  
**Template version:** 1.0.0  
**Terraform version:** >= 1.6  
**AWS provider version:** ~> 5.0
