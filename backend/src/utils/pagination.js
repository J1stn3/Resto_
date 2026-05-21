function parsePagination(query, defaultPerPage = 20) {
  let page = parseInt(query.page, 10);
  let perPage = parseInt(query.per_page, 10);
  if (isNaN(page) || page < 1) page = 1;
  if (isNaN(perPage) || perPage < 1) perPage = defaultPerPage;
  if (perPage > 100) perPage = 100;
  const offset = (page - 1) * perPage;
  return { page, perPage, offset };
}

function meta(page, perPage, total) {
  return {
    current_page: page,
    per_page: perPage,
    total,
    total_pages: Math.ceil(total / perPage) || 0,
  };
}

module.exports = { parsePagination, meta };
