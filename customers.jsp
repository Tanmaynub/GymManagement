<%@ page contentType="text/html;charset=UTF-8" language="java" import="java.sql.*,java.util.*,java.net.URLEncoder,shop.DBUtil" %>
<%
    request.setCharacterEncoding("UTF-8");

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        String result = "Nothing to do.";
        try (Connection con = DBUtil.getConnection()) {
            if ("add".equals(action)) {
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO Customer (name, phone) VALUES (?, ?)")) {
                    ps.setString(1, request.getParameter("name").trim());
                    ps.setString(2, request.getParameter("phone").trim());
                    ps.executeUpdate();
                    result = "Customer added.";
                }
            } else if ("delete".equals(action)) {
                try (PreparedStatement ps = con.prepareStatement("DELETE FROM Customer WHERE customer_id = ?")) {
                    ps.setInt(1, Integer.parseInt(request.getParameter("customer_id")));
                    result = ps.executeUpdate() > 0 ? "Customer deleted." : "Customer not found.";
                }
            }
        } catch (SQLException e) {
            result = (e.getErrorCode() == 1062) ? "That phone number is already registered."
                                                : "Database error: " + e.getMessage();
        } catch (NumberFormatException e) {
            result = "Invalid input.";
        }
        response.sendRedirect("customers.jsp?msg=" + URLEncoder.encode(result, "UTF-8"));
        return;
    }

    List<String[]> list = new ArrayList<>();
    String dbError = null;
    String sql = "SELECT c.customer_id, c.name, c.phone, COUNT(s.sale_id), COALESCE(SUM(s.total), 0) " +
                 "FROM Customer c LEFT JOIN Sale s ON s.customer_id = c.customer_id " +
                 "GROUP BY c.customer_id, c.name, c.phone ORDER BY c.name";
    try (Connection con = DBUtil.getConnection();
         Statement st = con.createStatement();
         ResultSet rs = st.executeQuery(sql)) {
        while (rs.next()) {
            list.add(new String[]{rs.getString(1), rs.getString(2), rs.getString(3),
                                  rs.getString(4), rs.getString(5)});
        }
    } catch (SQLException e) {
        dbError = e.getMessage();
    }
%>
<% String pageTitle = "Customers"; %>
<%@ include file="/WEB-INF/header.jspf" %>
<h1>Customers</h1>

<% if (dbError != null) { %>
  <div class="error">Database error: <%= DBUtil.esc(dbError) %></div>
<% } %>

<section class="card">
  <h2>Add a customer</h2>
  <form method="post" action="customers.jsp" class="inline-form">
    <input type="hidden" name="action" value="add">
    <div class="field"><label>Name</label><input name="name" required maxlength="80"></div>
    <div class="field"><label>Phone (10 digits)</label><input name="phone" required pattern="[0-9]{10}" maxlength="10"></div>
    <button class="btn" type="submit">Add customer</button>
  </form>
</section>

<section class="card">
  <h2>All customers (<%= list.size() %>)</h2>
  <% if (list.isEmpty()) { %>
    <p class="empty">No customers yet.</p>
  <% } else { %>
  <div class="table-wrap">
    <table>
      <tr><th>ID</th><th>Name</th><th>Phone</th><th>Bills</th><th>Total spent</th><th>Action</th></tr>
      <% for (String[] c : list) { %>
      <tr>
        <td><%= DBUtil.esc(c[0]) %></td><td><%= DBUtil.esc(c[1]) %></td><td><%= DBUtil.esc(c[2]) %></td>
        <td><%= DBUtil.esc(c[3]) %></td><td>Rs. <%= DBUtil.esc(c[4]) %></td>
        <td>
          <form method="post" action="customers.jsp" onsubmit="return confirm('Delete this customer? Their past bills are kept.');">
            <input type="hidden" name="action" value="delete">
            <input type="hidden" name="customer_id" value="<%= DBUtil.esc(c[0]) %>">
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