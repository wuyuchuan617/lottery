// https://athena.eslite.com/api/v2/search?q=%E5%B7%A5%E4%BD%9C%E6%8E%92%E6%AF%92&size=30&start=0
export const searchBook = async (queryString) => {
  const res = await fetch(
    `https://athena.eslite.com/api/v2/search?q=${queryString}`
  );
  const data = await res.json();
  return data.hits.hit;
};

// https://athena.eslite.com/api/v1/products/1001305312852268?datetime=2024042426714
export const searchSingleBook = async (queryString) => {
  const res = await fetch(
    `https://athena.eslite.com/api/v1/products/${queryString}`
  );
  const data = await res.json();
  return data;
};
