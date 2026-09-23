local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  s("id", {
    t("id SERIAL PRIMARY KEY"),
  }),
  s("serial", {
    t("SERIAL PRIMARY KEY"),
  }),
  s("ct", {
    t("CREATE TABLE "),
    i(1, "table_name"),
    t({ " (", "  id SERIAL PRIMARY KEY,", "  " }),
    i(2, ""),
    t({ "", ");" }),
  }),
}
