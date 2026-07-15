<script setup>
import { computed, ref } from "vue";
import {
  getDocumentValidation,
  validateDocument,
} from "./services/documentValidationService";

const file = ref(null);
const expectedType = ref("rg");
const candidateName = ref("");
const candidateCpf = ref("");
const loading = ref(false);
const result = ref(null);
const error = ref("");

const statusLabel = computed(
  () =>
    ({
      VALID: "Válido",
      INVALID: "Inválido",
      REVIEW: "Revisão necessária",
      PROCESSING: "Processando",
      FAILED: "Falha",
    })[result.value?.status] || result.value?.status,
);

function selectFile(event) {
  file.value = event.target.files?.[0] || null;
}

async function submit() {
  if (!file.value) return;

  loading.value = true;
  result.value = null;
  error.value = "";

  try {
    const queuedValidation = await validateDocument({
      file: file.value,
      expectedType: expectedType.value,
      candidateName: candidateName.value,
      candidateCpf: candidateCpf.value,
    });
    result.value = queuedValidation;
    result.value = await pollValidation(queuedValidation.id);
  } catch (requestError) {
    error.value = errorMessageFor(requestError);
  } finally {
    loading.value = false;
  }
}

function errorMessageFor(requestError) {
  if (requestError.message === "validation_timeout") {
    return "A análise ainda está processando. Consulte o resultado novamente em instantes.";
  }

  return (
    requestError.response?.data?.message ||
    "Não foi possível validar o documento."
  );
}

async function pollValidation(id) {
  const maxAttempts = 60;

  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    await wait(2000);

    const validation = await getDocumentValidation(id);
    result.value = validation;

    if (validation.status !== "PROCESSING") {
      return validation;
    }
  }

  throw new Error("validation_timeout");
}

function wait(milliseconds) {
  return new Promise((resolve) => {
    window.setTimeout(resolve, milliseconds);
  });
}
</script>

<template>
  <main>
    <section class="card">
      <p class="eyebrow">WORKVERSE DOCUMENT AI</p>
      <h1>Validação documental</h1>
      <p class="description">
        POC para RG, certidão de casamento e comprovante de endereço.
      </p>

      <label>
        Tipo esperado
        <select v-model="expectedType">
          <option value="rg">RG / CIN</option>
          <option value="marriage_certificate">Certidão de casamento</option>
          <option value="address_proof">Comprovante de endereço</option>
        </select>
      </label>

      <div class="grid">
        <label>
          Nome cadastrado
          <input v-model="candidateName" placeholder="Opcional" />
        </label>

        <label>
          CPF cadastrado
          <input v-model="candidateCpf" placeholder="Opcional" />
        </label>
      </div>

      <label class="upload">
        Arquivo
        <input
          type="file"
          accept=".pdf,image/jpeg,image/png,image/webp"
          @change="selectFile"
        />
        <span>{{ file?.name || "Selecione PDF, JPG, PNG ou WEBP" }}</span>
      </label>

      <button :disabled="!file || loading" @click="submit">
        {{ loading ? "Analisando documento..." : "Validar documento" }}
      </button>

      <p v-if="error" class="error">{{ error }}</p>
    </section>

    <section v-if="result" class="card result">
      <div class="result-header">
        <div>
          <p class="eyebrow">RESULTADO</p>
          <h2>{{ statusLabel }}</h2>
        </div>
        <strong v-if="result.confidence !== null && result.confidence !== undefined">
          {{ Math.round(result.confidence * 100) }}%
        </strong>
      </div>

      <p v-if="result.status === 'PROCESSING'" class="description">
        O arquivo foi recebido e a análise está em andamento.
      </p>

      <dl v-if="result.status !== 'PROCESSING'">
        <div>
          <dt>Tipo esperado</dt>
          <dd>{{ result.expected_type }}</dd>
        </div>
        <div>
          <dt>Tipo identificado</dt>
          <dd>{{ result.detected_type }}</dd>
        </div>
      </dl>

      <div v-if="result.status !== 'PROCESSING' && result.reasons?.length">
        <h3>Motivos</h3>
        <ul>
          <li v-for="reason in result.reasons" :key="reason">{{ reason }}</li>
        </ul>
      </div>

      <div v-if="result.status !== 'PROCESSING' && result.warnings?.length">
        <h3>Avisos</h3>
        <ul>
          <li v-for="warning in result.warnings" :key="warning">
            {{ warning }}
          </li>
        </ul>
      </div>

      <template v-if="result.status !== 'PROCESSING'">
        <h3>Campos extraídos</h3>
        <pre>{{ JSON.stringify(result.extracted_fields, null, 2) }}</pre>
      </template>
    </section>
  </main>
</template>
