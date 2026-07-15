import axios from 'axios';

export async function validateDocument({
  file,
  expectedType,
  candidateName,
  candidateCpf,
}) {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('expected_type', expectedType);

  if (candidateName) formData.append('candidate_name', candidateName);
  if (candidateCpf) formData.append('candidate_cpf', candidateCpf);

  const { data } = await axios.post('/api/v1/document_validations', formData, {
    timeout: 30000,
  });

  return data;
}

export async function getDocumentValidation(id) {
  const { data } = await axios.get(`/api/v1/document_validations/${id}`, {
    timeout: 10000,
  });

  return data;
}
