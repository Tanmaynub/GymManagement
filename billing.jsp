<%@ page contentType="text/html;charset=UTF-8" language="java" import="java.sql.*,java.util.*,java.math.BigDecimal,java.net.URLEncoder,shop.DBUtil" %>
<%
    request.setCharacterEncoding("UTF-8");

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String result = "";
        Connection con = null;
        boolean ok = false;
        try {
            con = DBUtil.getConnection();
            con.setAutoCommit(false);

            int pid = Integer.parseInt(request.getParameter("product_id"));
            int qty = Integer.parseInt(request.getParameter("quantity"));
            String cid = request.getParameter("customer_id");
            BigDecimal price = null;
            int stock = 0;

            if (qty <= 0) {
                result = "Quantity must be at least 1.";
            } else {
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT price, stock FROM Product WHERE product_id = ? FOR UPDATE")) {
                    ps.setInt(1, pid);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) { price = rs.getBigDecimal(1); stock = rs.getInt(2); }
                    }
                }
                if (price == null) {
                    result = "Product not found.";
                } else if (stock < qty) {
                    result = "Only " + stock + " in stock.";
                } else {
                    try (PreparedStatement up = con.prepareStatement(
                            "UPDATE Product SET stock = stock - ? WHERE product_id = ?")) {
                        up.setInt(1, qty);
                        up.setInt(2, pid);
                        up.executeUpdate();
                    }
                    BigDecimal total = price.multiply(BigDecimal.valueOf(qty));
                    try (PreparedStatement ins = con.prepareStatement(
                            "INSERT INTO Sale (customer_id, product_id, quantity, unit_price, total) " +
                            "VALUES (?, ?, ?, ?, ?)")) {
                        if (cid == null || cid.isEmpty()) ins.setNull(1, Types.INTEGER);
                        else ins.setInt(1, Integer.parseInt(cid));
                        ins.setInt(2, pid);
                        ins.setInt(3, qty);
                        ins.setBigDecimal(4, price);
                        ins.setBigDecimal(5, total);
                        ins.executeUpdate();
                    }
                    con.commit();
                    ok = true;
                    result = "Sale recorded. Total: Rs. " + total;
                }
            }
        } catch (SQLException e) {
            result = "Database error: " + e.getMessage();
        } catch (NumberFormatException e) {
            result = "Invalid input.";
        } finally {
            if (con != null) {
                try { if (!ok) con.rollback(); con.close(); } catch (SQLException ignore) { }
            }
        }
        response.sendRedirect("billing.jsp?msg=" + URLEncoder.encode(result, "UTF-8"));
        return;
    }

    List<String[]> products = new ArrayList<>();
    List<String[]> customers = new ArrayList<>();
    List<String[]> sales = new ArrayList<>();
    String dbError = null;

    try (Connection con = DBUtil.getConnection()) {
        try (Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(
                 "SELECT product_id, name, price, stock FROM Product WHERE stock > 0 ORDER BY name")) {
            while (rs.next()) {
                products.add(new String[]{rs.getString(1), rs.getString(2), rs.getString(3), rs.getString(4)});
            }
        }
        try (Statement st = con.createStatement();
             ResultSet rs = st.executeQuery("SELECT customer_id, name, phone FROM Customer ORDER BY name")) {
            while (rs.next()) {
                customers.add(new String[]{rs.getString(1), rs.getString(2), rs.getString(3)});
            }
        }
        String sql = "SELECT s.sale_id, s.sale_date, COALESCE(c.name, 'Walk-in'), p.name, " +
                     "s.quantity, s.unit_price, s.total " +
                     "FROM Sale s JOIN Product p ON s.product_id = p.product_id " +
                     "LEFT JOIN Customer c ON s.customer_id = c.customer_id " +
                     "ORDER BY s.sale_id DESC LIMIT 20";
        try (Statement st = con.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                sales.add(new String[]{rs.getString(1), rs.getString(2), rs.getString(3), rs.getString(4),
                                       rs.getString(5), rs.getString(6), rs.getString(7)});
            }
        }
    } catch (SQLException e) {
        dbError = e.getMessage();
    }
%>
<% String pageTitle = "Billing"; %>
<%@ include file="/WEB-INF/header.jspf" %>
<h1>Billing</h1>

<% if (dbError != null) { %>
  <div class="error">Database error: <%= DBUtil.esc(dbError) %></div>
<% } %>

<section class="card">
  <h2>New sale</h2>
  <form method="post" action="billing.jsp" class="inline-form">
    <div class="field"><label>Customer</label>
      <select name="customer_id">
        <option value="">Walk-in customer</option>
        <% for (String[] c : customers) { %>
          <option value="<%= DBUtil.esc(c[0]) %>"><%= DBUtil.esc(c[1]) %> (<%= DBUtil.esc(c[2]) %>)</option>
        <% } %>
      </select>
    </div>
    <div class="field"><label>Product</label>
      <select name="product_id" required>
        <option value="">-- select --</option>
        <% for (String[] p : products) { %>
          <option value="<%= DBUtil.esc(p[0]) %>"><%= DBUtil.esc(p[1]) %> &ndash; Rs. <%= DBUtil.esc(p[2]) %> (<%= DBUtil.esc(p[3]) %> left)</option>
        <% } %>
      </select>
    </div>
    <div class="field"><label>Quantity</label><input type="number" name="quantity" min="1" value="1" required></div>
    <button class="btn" type="submit">Create bill</button>
  </form>
</section>

<section class="card">
  <h2>Recent sales</h2>
  <% if (sales.isEmpty()) { %>
    <p class="empty">No sales recorded yet.</p>
  <% } else { %>
  <div class="table-wrap">
    <table>
      <tr><th>Bill</th><th>Date</th><th>Customer</th><th>Product</th><th>Qty</th><th>Rate</th><th>Total</th></tr>
      <% for (String[] s : sales) { %>
      <tr>
        <td>#<%= DBUtil.esc(s[0]) %></td><td><%= DBUtil.esc(s[1]) %></td><td><%= DBUtil.esc(s[2]) %></td>
        <td><%= DBUtil.esc(s[3]) %></td><td><%= DBUtil.esc(s[4]) %></td>
        <td>Rs. <%= DBUtil.esc(s[5]) %></td><td>Rs. <%= DBUtil.esc(s[6]) %></td>
      </tr>
      <% } %>
    </table>
  </div>
  <% } %>
</section>
<%@ include file="/WEB-INF/footer.jspf" %>