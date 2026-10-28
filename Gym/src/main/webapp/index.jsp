<%@ page contentType="text/html;charset=UTF-8" language="java" import="java.sql.*,java.util.*,gym.DBUtil" %>
<% String pageTitle = "Dashboard"; %>
<%@ include file="/WEB-INF/header.jspf" %>
<%
    int total = 0, active = 0, expiring = 0, today = 0;
    List<String[]> soon = new ArrayList<>();
    String dbError = null;

    try (Connection con = DBUtil.getConnection()) {
        String stats =
            "SELECT (SELECT COUNT(*) FROM Member), " +
            "(SELECT COUNT(*) FROM Member WHERE expiry_date >= CURDATE()), " +
            "(SELECT COUNT(*) FROM Member WHERE expiry_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)), " +
            "(SELECT COUNT(*) FROM Attendance WHERE visit_date = CURDATE())";
        try (Statement st = con.createStatement(); ResultSet rs = st.executeQuery(stats)) {
            if (rs.next()) {
                total = rs.getInt(1); active = rs.getInt(2); expiring = rs.getInt(3); today = rs.getInt(4);
            }
        }
        String list =
            "SELECT m.member_id, m.name, m.phone, p.plan_name, m.expiry_date " +
            "FROM Member m JOIN Plan p ON m.plan_id = p.plan_id " +
            "WHERE m.expiry_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY) " +
            "ORDER BY m.expiry_date";
        try (Statement st = con.createStatement(); ResultSet rs = st.executeQuery(list)) {
            while (rs.next()) {
                soon.add(new String[]{rs.getString(1), rs.getString(2), rs.getString(3),
                                      rs.getString(4), rs.getString(5)});
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
  <div class="stat"><div class="num"><%= total %></div><div class="lbl">Total members</div></div>
  <div class="stat"><div class="num"><%= active %></div><div class="lbl">Active memberships</div></div>
  <div class="stat"><div class="num"><%= expiring %></div><div class="lbl">Expiring in 7 days</div></div>
  <div class="stat"><div class="num"><%= today %></div><div class="lbl">Check-ins today</div></div>
</section>

<section class="card">
  <h2>Memberships expiring this week</h2>
  <% if (soon.isEmpty()) { %>
    <p class="empty">No memberships expiring in the next 7 days.</p>
  <% } else { %>
  <div class="table-wrap">
    <table>
      <tr><th>ID</th><th>Name</th><th>Phone</th><th>Plan</th><th>Expires</th></tr>
      <% for (String[] r : soon) { %>
      <tr>
        <td><%= DBUtil.esc(r[0]) %></td><td><%= DBUtil.esc(r[1]) %></td>
        <td><%= DBUtil.esc(r[2]) %></td><td><%= DBUtil.esc(r[3]) %></td>
        <td><%= DBUtil.esc(r[4]) %></td>
      </tr>
      <% } %>
    </table>
  </div>
  <% } %>
</section>
