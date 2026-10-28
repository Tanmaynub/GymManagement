<%@ page contentType="text/html;charset=UTF-8" language="java" import="java.sql.*,java.util.*,java.net.URLEncoder,gym.DBUtil" %>
<%
    request.setCharacterEncoding("UTF-8");

   
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        String result = "Nothing to do.";
        try (Connection con = DBUtil.getConnection()) {
            if ("add".equals(action)) {
                String sql = "INSERT INTO Member (name, phone, email, plan_id, join_date, expiry_date) " +
                             "SELECT ?, ?, ?, plan_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL duration_months MONTH) " +
                             "FROM Plan WHERE plan_id = ?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, request.getParameter("name").trim());
                    ps.setString(2, request.getParameter("phone").trim());
                    ps.setString(3, request.getParameter("email").trim());
                    ps.setInt(4, Integer.parseInt(request.getParameter("plan_id")));
                    result = ps.executeUpdate() > 0 ? "Member added." : "Selected plan does not exist.";
                }
            } else if ("renew".equals(action)) {
                String sql = "UPDATE Member m JOIN Plan p ON m.plan_id = p.plan_id " +
                             "SET m.expiry_date = DATE_ADD(GREATEST(m.expiry_date, CURDATE()), INTERVAL p.duration_months MONTH) " +
                             "WHERE m.member_id = ?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setInt(1, Integer.parseInt(request.getParameter("member_id")));
                    result = ps.executeUpdate() > 0 ? "Membership renewed." : "Member not found.";
                }
            } else if ("delete".equals(action)) {
                try (PreparedStatement ps = con.prepareStatement("DELETE FROM Member WHERE member_id = ?")) {
                    ps.setInt(1, Integer.parseInt(request.getParameter("member_id")));
                    result = ps.executeUpdate() > 0 ? "Member deleted." : "Member not found.";
                }
            }
        } catch (SQLException e) {
            result = (e.getErrorCode() == 1062) ? "That email is already registered." : "Database error: " + e.getMessage();
        } catch (NumberFormatException e) {
            result = "Invalid input.";
        }
        response.sendRedirect("members.jsp?msg=" + URLEncoder.encode(result, "UTF-8"));
        return;
    }


    String q = request.getParameter("q");
    if (q == null) q = "";
    List<String[]> plans = new ArrayList<>();
    List<String[]> members = new ArrayList<>();
    String dbError = null;

    try (Connection con = DBUtil.getConnection()) {
        try (Statement st = con.createStatement();
             ResultSet rs = st.executeQuery("SELECT plan_id, plan_name, fee FROM Plan ORDER BY duration_months")) {
            while (rs.next()) plans.add(new String[]{rs.getString(1), rs.getString(2), rs.getString(3)});
        }
        String sql = "SELECT m.member_id, m.name, m.phone, m.email, p.plan_name, m.join_date, m.expiry_date, " +
                     "(m.expiry_date >= CURDATE()) AS active " +
                     "FROM Member m JOIN Plan p ON m.plan_id = p.plan_id " +
                     "WHERE m.name LIKE ? ORDER BY m.member_id DESC";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, "%" + q + "%");
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    members.add(new String[]{rs.getString(1), rs.getString(2), rs.getString(3), rs.getString(4),
                                             rs.getString(5), rs.getString(6), rs.getString(7), rs.getBoolean(8) ? "1" : "0"});
                }
            }
        }
    } catch (SQLException e) {
        dbError = e.getMessage();
    }
%>
<% String pageTitle = "Members"; %>
<%@ include file="/WEB-INF/header.jspf" %>
<h1>Members</h1>

<% if (dbError != null) { %>
  <div class="error">Database error: <%= DBUtil.esc(dbError) %></div>
<% } %>

<section class="card">
  <h2>Register new member</h2>
  <form method="post" action="members.jsp" class="inline-form">
    <input type="hidden" name="action" value="add">
    <div class="field"><label>Full name</label><input name="name" required maxlength="80"></div>
    <div class="field"><label>Phone (10 digits)</label><input name="phone" required pattern="[0-9]{10}" maxlength="10"></div>
    <div class="field"><label>Email</label><input type="email" name="email" required maxlength="100"></div>
    <div class="field"><label>Plan</label>
      <select name="plan_id" required>
        <% for (String[] p : plans) { %>
          <option value="<%= DBUtil.esc(p[0]) %>"><%= DBUtil.esc(p[1]) %> (Rs. <%= DBUtil.esc(p[2]) %>)</option>
        <% } %>
      </select>
    </div>
    <button class="btn" type="submit">Add member</button>
  </form>
</section>

<section class="card">
  <h2>All members (<%= members.size() %>)</h2>
  <form method="get" action="members.jsp" class="search">
    <input name="q" placeholder="Search by name" value="<%= DBUtil.esc(q) %>">
    <button class="btn ghost" type="submit">Search</button>
  </form>
  <% if (members.isEmpty()) { %>
    <p class="empty">No members found.</p>
  <% } else { %>
  <div class="table-wrap">
    <table>
      <tr><th>ID</th><th>Name</th><th>Phone</th><th>Email</th><th>Plan</th><th>Joined</th><th>Expires</th><th>Status</th><th>Actions</th></tr>
      <% for (String[] m : members) { boolean isActive = "1".equals(m[7]); %>
      <tr>
        <td><%= DBUtil.esc(m[0]) %></td><td><%= DBUtil.esc(m[1]) %></td><td><%= DBUtil.esc(m[2]) %></td>
        <td><%= DBUtil.esc(m[3]) %></td><td><%= DBUtil.esc(m[4]) %></td><td><%= DBUtil.esc(m[5]) %></td>
        <td><%= DBUtil.esc(m[6]) %></td>
        <td><span class="badge <%= isActive ? "ok" : "bad" %>"><%= isActive ? "Active" : "Expired" %></span></td>
        <td>
          <form method="post" action="members.jsp">
            <input type="hidden" name="action" value="renew">
            <input type="hidden" name="member_id" value="<%= DBUtil.esc(m[0]) %>">
            <button class="btn small ghost" type="submit">Renew</button>
          </form>
          <form method="post" action="members.jsp" onsubmit="return confirm('Delete this member and their attendance records?');">
            <input type="hidden" name="action" value="delete">
            <input type="hidden" name="member_id" value="<%= DBUtil.esc(m[0]) %>">
            <button class="btn small danger" type="submit">Delete</button>
          </form>
        </td>
      </tr>
      <% } %>
    </table>
  </div>
  <% } %>
</section>
