<%@ page contentType="text/html;charset=UTF-8" language="java" import="java.sql.*,java.util.*,java.net.URLEncoder,gym.DBUtil" %>
<%
    request.setCharacterEncoding("UTF-8");

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String result;
        String sql = "INSERT INTO Attendance (member_id, visit_date, check_in) " +
                     "SELECT member_id, CURDATE(), CURTIME() FROM Member " +
                     "WHERE member_id = ? AND expiry_date >= CURDATE() " +
                     "AND NOT EXISTS (SELECT 1 FROM Attendance a WHERE a.member_id = ? AND a.visit_date = CURDATE())";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            int id = Integer.parseInt(request.getParameter("member_id"));
            ps.setInt(1, id);
            ps.setInt(2, id);
            result = ps.executeUpdate() > 0
                   ? "Check-in recorded."
                   : "Not recorded: membership expired, unknown member, or already checked in today.";
        } catch (SQLException e) {
            result = "Database error: " + e.getMessage();
        } catch (NumberFormatException e) {
            result = "Please select a member.";
        }
        response.sendRedirect("attendance.jsp?msg=" + URLEncoder.encode(result, "UTF-8"));
        return;
    }

    List<String[]> activeMembers = new ArrayList<>();
    List<String[]> todayList = new ArrayList<>();
    String dbError = null;
    try (Connection con = DBUtil.getConnection()) {
        try (Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(
                 "SELECT member_id, name FROM Member WHERE expiry_date >= CURDATE() ORDER BY name")) {
            while (rs.next()) activeMembers.add(new String[]{rs.getString(1), rs.getString(2)});
        }
        try (Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(
                 "SELECT m.member_id, m.name, a.check_in FROM Attendance a " +
                 "JOIN Member m ON a.member_id = m.member_id " +
                 "WHERE a.visit_date = CURDATE() ORDER BY a.check_in DESC")) {
            while (rs.next()) todayList.add(new String[]{rs.getString(1), rs.getString(2), rs.getString(3)});
        }
    } catch (SQLException e) {
        dbError = e.getMessage();
    }
%>
<% String pageTitle = "Attendance"; %>
<%@ include file="/WEB-INF/header.jspf" %>
<h1>Attendance</h1>

<% if (dbError != null) { %>
  <div class="error">Database error: <%= DBUtil.esc(dbError) %></div>
<% } %>

<section class="card">
  <h2>Check a member in</h2>
  <form method="post" action="attendance.jsp" class="inline-form">
    <div class="field"><label>Active member</label>
      <select name="member_id" required>
        <option value="">-- select --</option>
        <% for (String[] m : activeMembers) { %>
          <option value="<%= DBUtil.esc(m[0]) %>">#<%= DBUtil.esc(m[0]) %> &ndash; <%= DBUtil.esc(m[1]) %></option>
        <% } %>
      </select>
    </div>
    <button class="btn" type="submit">Check in</button>
  </form>
</section>

<section class="card">
  <h2>Today's check-ins (<%= todayList.size() %>)</h2>
  <% if (todayList.isEmpty()) { %>
    <p class="empty">Nobody has checked in yet today.</p>
  <% } else { %>
  <div class="table-wrap">
    <table>
      <tr><th>Member ID</th><th>Name</th><th>Time</th></tr>
      <% for (String[] r : todayList) { %>
      <tr><td><%= DBUtil.esc(r[0]) %></td><td><%= DBUtil.esc(r[1]) %></td><td><%= DBUtil.esc(r[2]) %></td></tr>
      <% } %>
    </table>
  </div>
  <% } %>
</section>
