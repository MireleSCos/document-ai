# Document AI 

https://github.com/user-attachments/assets/7d43cdf6-ccb9-4e7c-9ed4-71398e0341b8

POC reutilizável para validação visual de:

- RG/CIN;
- certidão de casamento;
- comprovante de endereço.

A API recebe uma imagem ou PDF, cria uma validação em `PROCESSING`, processa a análise em background via Sidekiq e permite consultar o resultado final por ID:

- `VALID`;
- `INVALID`;
- `REVIEW`.

> `VALID` significa que o arquivo corresponde ao tipo esperado, está legível e atende às regras configuradas. Não representa confirmação de autenticidade oficial nem substitui consulta a órgãos emissores.

## Estrutura

```text
api/   Ruby on Rails API + Mongoid + Sidekiq
web/   Vue 3 + Vite
```

## Requisitos

- Ruby 3.2+
- Node 20+
- MongoDB
- Redis
- Poppler (`pdftoppm`)
- chave de API de um modelo multimodal compatível com a OpenAI Responses API

No macOS:

```bash
brew install poppler mongodb-community redis
```

Também é possível subir MongoDB e Redis com Docker:

```bash
docker compose up -d
```

## 1. Configurar a API

```bash
cd api
cp .env.example .env
bundle install
bin/rails db:mongoid:create_indexes
bin/rails server -p 3000
```

Edite `.env`:

```env
OPENAI_API_KEY=sua-chave
OPENAI_MODEL=seu-modelo-multimodal
MONGODB_URI=mongodb://localhost:27017/workverse_document_ai_development
REDIS_URL=redis://localhost:6379/0
DOCUMENT_AI_MIN_CONFIDENCE=0.90
DOCUMENT_AI_SHADOW_MODE=true
```

Em outro terminal:

```bash
cd api
bundle exec sidekiq
```

## 2. Configurar o Vue

```bash
cd web
npm install
npm run dev
```

Abra:

```text
http://localhost:5173
```

## Endpoint

```text
POST /api/v1/document_validations
Content-Type: multipart/form-data
```

Campos:

| Campo | Obrigatório | Valores |
|---|---:|---|
| `file` | sim | PDF, JPG, PNG ou WEBP |
| `expected_type` | sim | `rg`, `marriage_certificate`, `address_proof` |
| `candidate_name` | não | nome cadastrado |
| `candidate_cpf` | não | CPF cadastrado |
| `project_id` | não | ObjectId |
| `person_id` | não | ObjectId |

Exemplo:

```bash
curl -X POST http://localhost:3000/api/v1/document_validations \
  -F "file=@/caminho/documento.pdf" \
  -F "expected_type=address_proof" \
  -F "candidate_name=Maria da Silva"
```

O `POST` retorna `202 Accepted` com o registro em `PROCESSING`. Consulte o resultado em:

```text
GET /api/v1/document_validations/:id
```

## Modo sombra

Para analisar documentos reais sem alterar o fluxo atual:

```ruby
DocumentShadowValidationJob.perform_async(document.id.to_s)
```

O job:

1. lê o registro original;
2. baixa os arquivos;
3. executa a IA;
4. salva em `document_validations`;
5. não altera `status` nem `status_message` do documento original.

Para adaptar à collection real da Workverse, altere:

```text
api/app/models/source_document.rb
api/app/jobs/document_shadow_validation_job.rb
```

## Segurança para POC

- `store: false` é enviado ao provider;
- o arquivo temporário é apagado ao terminar;
- limite padrão: 15 MB e cinco páginas;
- o retorno bruto do provider não é persistido por padrão;
- não use documentos pessoais reais fora de ambiente autorizado;
- revise LGPD, retenção, contrato do fornecedor e controles de acesso antes de produção.

## Próximos passos

1. executar com documentos controlados;
2. testar uma amostra histórica revisada;
3. medir falso positivo entre documentos marcados como `VALID`;
4. manter `REVIEW` no fluxo humano;
5. adicionar regras por projeto;
6. somente depois avaliar autoaprovação.


## Se aparecer `rails new APP_PATH`

Execute a aplicação pelo binário local dentro de `api`:

```bash
bin/rails server -p 3000
```

O projeto inclui `api/bin/rails`. Evite usar apenas `rails s` se o shell estiver resolvendo outro executável global.
