const express = require('express');
const {
    getMedicalHistory,
    createMedicalRecord,
    getAllergies,
    createAllergy,
    getMedications,
    createMedication,
    getFamilyHistory,
    createFamilyHistory
} = require('./medical.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validate.middleware');
const {
    createMedicalRecordSchema,
    createAllergySchema,
    createMedicationSchema,
    createFamilyHistorySchema
} = require('./medical.validator');
const router = express.Router();

router.use(verifyToken);

// historial_medico -> GET/POST /api/medical-history
router.get('/', getMedicalHistory);
router.post('/', validate(createMedicalRecordSchema), createMedicalRecord);

// alergias -> GET/POST /api/medical-history/allergies
router.get('/allergies', getAllergies);
router.post('/allergies', validate(createAllergySchema), createAllergy);

// medicamentos -> GET/POST /api/medical-history/medications
router.get('/medications', getMedications);
router.post('/medications', validate(createMedicationSchema), createMedication);

// antecedentes_familiares -> GET/POST /api/medical-history/family-history
router.get('/family-history', getFamilyHistory);
router.post('/family-history', validate(createFamilyHistorySchema), createFamilyHistory);

module.exports = router;
