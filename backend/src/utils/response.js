function success(res, message, data = null, status = 200) {
  const body = { success: true, message };
  if (data !== null) body.data = data;
  return res.status(status).json(body);
}

function paginated(res, message, data, meta) {
  return res.status(200).json({ success: true, message, data, meta });
}

function error(res, message, status = 400, errorCode = null) {
  const body = { success: false, message };
  if (errorCode) body.error = errorCode;
  return res.status(status).json(body);
}

module.exports = { success, paginated, error };
