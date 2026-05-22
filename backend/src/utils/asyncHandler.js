/** Wrap async route handlers so errors reach Express error middleware. */
function asyncHandler(fn) {
  if (typeof fn !== 'function') {
    throw new TypeError(
      `Route handler must be a function, got ${fn === undefined ? 'undefined' : typeof fn}`,
    );
  }
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

module.exports = asyncHandler;
