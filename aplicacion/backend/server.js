const express = require('express');
const cors = require('cors');
const app = express();
app.use(cors());

app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    version: process.env.APP_VERSION || '1.0.0',
    mensaje: 'Backend operativo en AWS ECS Fargate',
    fecha: new Date().toISOString()
  });
});

app.get('/api/tareas', (req, res) => {
  res.json([
    { id: 1, fase: 'Pipeline 1 (IaC)', detalle: 'VPC, ECR y ECS creados con Terraform' },
    { id: 2, fase: 'Pipeline 2 (CI)', detalle: 'Pruebas superadas e imagen versionada en ECR' },
    { id: 3, fase: 'Pipeline 3 (CD)', detalle: 'Task Definition actualizada y monitoreada' }
  ]);
});

if (require.main === module) {
  app.listen(3000, '0.0.0.0', () => console.log('API escuchando en puerto 3000'));
}
module.exports = app;
