const mongoose = require('mongoose');

const changeRequestSchema = new mongoose.Schema({
  employeeId: { type: String, required: true, index: true },
  full_name: { type: String },                // ✅ added for readability
  field: { type: String, required: true },        // e.g., "mobile_number", "dob"
  oldValue: { type: String },
  newValue: { type: String, required: true },
  requestedBy: { type: String },                  // who requested (employee id)
  requestedByName: { type: String },              // ✅ added: store requester name
  status: {
    type: String,
    enum: ['pending', 'approved', 'declined'],
    default: 'pending',
  },
  createdAt: { type: Date, default: Date.now },
  resolvedAt: { type: Date },
  resolvedBy: { type: String },
});

const ChangeRequest =
  mongoose.models.ChangeRequest ||
  mongoose.model('change_request', changeRequestSchema);

module.exports = ChangeRequest;
