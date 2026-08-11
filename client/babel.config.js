module.exports = (api) => {
  api.cache(true);

  const presets = ["@babel/preset-env", "@babel/preset-react"];

  const env = {
    test: {
      presets: [["@babel/preset-env", { targets: { node: "current" } }]],
    },
  };

  return {
    presets,
    env,
  };
};
