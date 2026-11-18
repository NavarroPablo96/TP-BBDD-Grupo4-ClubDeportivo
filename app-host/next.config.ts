import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Drivers nativos de SQL Server: no se empaquetan, se cargan desde node_modules.
  serverExternalPackages: ["mssql", "msnodesqlv8"],
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
