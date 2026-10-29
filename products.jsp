<%@ page contentType="text/html;charset=UTF-8" language="java" import="java.sql.*,java.util.*,java.math.BigDecimal,java.net.URLEncoder,shop.DBUtil" %>
<%
    request.setCharacterEncoding("UTF-8");

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        String result = "Nothing to do.";
        try (Connection con = DBUtil.getConnection()) {
            if ("add".equals(action)) {
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO Product (name, price, stock, reorder_level) VALUES (?, ?, ?, ?)")) {
                    ps.setString(1, request.getParameter("name").trim());
                    ps.setBigDecimal(2, new BigDecimal(request.getParameter("price")));
                    ps.setInt(3, Integer.parseInt(request.getParameter("stock")));
                    ps.setInt(4, Integer.parseInt(request.getParameter("reorder")));
                    ps.executeUpdate();
                    result = "Product added.";
                }
            } else if ("restock".equals(action)) {
                int qty = Integer.parseInt(request.getParameter("qty"));
                if (qty <= 0) {
                    result = "Restock quantity must be at least 1.";
                } else {
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE Product SET stock = stock + ? WHERE product_id = ?")) {
                        ps.setInt(1, qty);
                        ps.setInt(2, Integer.parseInt(request.getParameter("product_id")));
                        result = ps.executeUpdate() > 0 ? "Stock updated." : "Product not found.";
                    }
                }
            } else if ("price".equals(action)) {
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE Product SET price = ? WHERE product_id = ?")) {
                    ps.setBigDecimal(1, new BigDecimal(request.getParameter("price")));
                    ps.setInt(2, Integer.parseInt(request.getParameter("product_id")));
                    result = ps.executeUpdate() > 0 ? "Price updated." : "Product not found.";
                }
            } else if ("delete".equals(action)) {
                try (PreparedStatement ps = con.prepareStatement("DELETE FROM Product WHERE product_id = ?")) {
                    ps.setInt(1, Integer.parseInt(request.getParameter("product_id")));
                    result = ps.executeUpdate() > 0 ? "Product deleted." : "Product not found.";
                }
            }
        } catch (SQLException e) {
            int code = e.getErrorCode();
            if (code == 1062)      result = "A product with that name already exists.";
            else if (code == 1451) result = "Cannot delete: this product has sales records.";
            else                   result = "Database error: " + e.getMessage();
        } catch (NumberFormatException e) {
            result = "Invalid number entered.";
        }
        response.sendRedirect("products.jsp?msg=" + URLEncoder.encode(result, "UTF-8"));
        return;
    }

    List<String[]> items = new ArrayList<>();
    String dbError = null;
    try (Connection con = DBUtil.getConnection();
         Statement st = con.createStatement();
         ResultSet rs = st.executeQuery(
             "SELECT product_id, name, price, stock, reorder_level FROM Product ORDER BY name")) {
        while (rs.next()) {
            items.add(new String[]{rs.getString(1), rs.getString(2), rs.getString(3),
                                   rs.getString(4), rs.getString(5)});
        }
    } catch (SQLException e) {
        dbError = e.getMessage();
    }
%>
<% String pageTitle = "Products"; %>
<%@ include file="/WEB-INF/header.jspf" %>
<h1>Products</h1>

<% if (dbError != null) { %>
  <div class="error">Database error: <%= DBUtil.esc(dbError) %></div>
<% } %>

<section class="card">
  <h2>Add a product</h2>
  <form method="post" action="products.jsp" class="inline-form">
    <input type="hidden" name="action" value="add">
    <div class="field"><label>Product name</label><input name="name" required maxlength="80"></div>
    <div class="field"><label>Price (Rs.)</label><input type="number" name="price" min="0" step="0.01" required></div>
    <div class="field"><label>Opening stock</label><input type="number" name="stock" min="0" value="0" required></div>
    <div class="field"><label>Reorder level</label><input type="number" name="reorder" min="0" value="5" required></div>
    <button class="btn" type="submit">Add product</button>
  </form>
</section>

<section class="card">
  <h2>Inventory (<%= items.size() %>)</h2>
  <% if (items.isEmpty()) { %>
    <p class="empty">No products yet.</p>
  <% } else { %>
  <div class="table-wrap">
    <table>
      <tr><th>ID</th><th>Name</th><th>Price</th><th>Stock</th><th>Status</th><th>Actions</th></tr>
      <% for (String[] p : items) {
           boolean isLow = Integer.parseInt(p[3]) <= Integer.parseInt(p[4]); %>
      <tr>
        <td><%= DBUtil.esc(p[0]) %></td>
        <td><%= DBUtil.esc(p[1]) %></td>
        <td>Rs. <%= DBUtil.esc(p[2]) %></td>
        <td><%= DBUtil.esc(p[3]) %></td>
        <td><span class="badge <%= isLow ? "bad" : "ok" %>"><%= isLow ? "Low stock" : "In stock" %></span></td>
        <td>
          <form method="post" action="products.jsp">
            <input type="hidden" name="action" value="price">
            <input type="hidden" name="product_id" value="<%= DBUtil.esc(p[0]) %>">
            <input class="mini" type="number" name="price" min="0" step="0.01" placeholder="New price" required>
            <button class="btn small ghost" type="submit">Set price</button>
          </form>
          <form method="post" action="products.jsp">
            <input type="hidden" name="action" value="restock">
            <input type="hidden" name="product_id" value="<%= DBUtil.esc(p[0]) %>">
            <input class="mini" type="number" name="qty" min="1" placeholder="Qty" required>
            <button class="btn small ghost" type="submit">Restock</button>
          </form>
          <form method="post" action="products.jsp" onsubmit="return confirm('Delete this product?');">
            <input type="hidden" name="action" value="delete">
            <input type="hidden" name="product_id" value="<%= DBUtil.esc(p[0]) %>">
            <button class="btn small danger" type="submit">Delete</button>
          </form>
        </td>
      </tr>
      <% } %>
    </table>
  </div>
  <% } %>
</section>
<%@ include file="/WEB-INF/footer.jspf" %>