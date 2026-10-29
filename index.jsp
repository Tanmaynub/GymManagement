<%@ page contentType="text/html;charset=UTF-8" language="java" import="java.sql.*,java.util.*,shop.DBUtil" %>
<% String pageTitle = "Dashboard"; %>
<%@ include file="/WEB-INF/header.jspf" %>
<%
    int products = 0, lowCount = 0, customers = 0, billsToday = 0;
    String salesToday = "0.00";
    List<String[]> low = new ArrayList<>();
    String dbError = null;

    try (Connection con = DBUtil.getConnection()) {
        String stats =
            "SELECT (SELECT COUNT(*) FROM Product), " +
            "(SELECT COUNT(*) FROM Product WHERE stock <= reorder_level), " +
            "(SELECT COUNT(*) FROM Customer), " +
            "(SELECT COUNT(*) FROM Sale WHERE DATE(sale_date) = CURDATE()), " +
            "(SELECT COALESCE(SUM(total), 0) FROM Sale WHERE DATE(sale_date) = CURDATE())";
        try (Statement st = con.createStatement(); ResultSet rs = st.executeQuery(stats)) {
            if (rs.next()) {
                products = rs.getInt(1); lowCount = rs.getInt(2); customers = rs.getInt(3);
                billsToday = rs.getInt(4); salesToday = rs.getString(5);
            }
        }
        try (Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(
                 "SELECT product_id, name, stock, reorder_level FROM Product " +
                 "WHERE stock <= reorder_level ORDER BY stock")) {
            while (rs.next()) {
                low.add(new String[]{rs.getString(1), rs.getString(2), rs.getString(3), rs.getString(4)});
            }
        }
    } catch (SQLException e) {
        dbError = e.getMessage();
    }
%>
<h1>Dashboard</h1>

<% if (dbError != null) { %>
  <div class="error">Database error: <%= DBUtil.esc(dbError) %></div>
<% } %>

<section class="stats">
  <div class="stat"><div class="num"><%= products %></div><div class="lbl">Products</div></div>
  <div class="stat"><div class="num"><%= lowCount %></div><div class="lbl">Low-stock items</div></div>
  <div class="stat"><div class="num"><%= customers %></div><div class="lbl">Customers</div></div>
  <div class="stat"><div class="num"><%= billsToday %></div><div class="lbl">Bills today</div></div>
  <div class="stat"><div class="num">Rs. <%= DBUtil.esc(salesToday) %></div><div class="lbl">Sales today</div></div>
</section>

<section class="card">
  <h2>Items to reorder</h2>
  <% if (low.isEmpty()) { %>
    <p class="empty">All products are above their reorder level.</p>
  <% } else { %>
  <div class="table-wrap">
    <table>
      <tr><th>ID</th><th>Product</th><th>In stock</th><th>Reorder level</th></tr>
      <% for (String[] r : low) { %>
      <tr>
        <td><%= DBUtil.esc(r[0]) %></td><td><%= DBUtil.esc(r[1]) %></td>
        <td><span class="badge bad"><%= DBUtil.esc(r[2]) %></span></td>
        <td><%= DBUtil.esc(r[3]) %></td>
      </tr>
      <% } %>
    </table>
  </div>
  <% } %>
</section>
<%@ include file="/WEB-INF/footer.jspf" %>