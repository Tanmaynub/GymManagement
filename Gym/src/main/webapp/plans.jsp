<%@ page contentType="text/html;charset=UTF-8" language="java" import="java.sql.*,java.util.*,java.net.URLEncoder,gym.DBUtil" %>
<%
    request.setCharacterEncoding("UTF-8");

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String result;
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                 "INSERT INTO Plan (plan_name, duration_months, fee) VALUES (?, ?, ?)")) {
            ps.setString(1, request.getParameter("plan_name").trim());
            ps.setInt(2, Integer.parseInt(request.getParameter("duration")));
            ps.setBigDecimal(3, new java.math.BigDecimal(request.getParameter("fee")));
            ps.executeUpdate();
            result = "Plan added.";
        } catch (SQLException e) {
            result = (e.getErrorCode() == 1062) ? "A plan with that name already exists." : "Database error: " + e.getMessage();
        } catch (NumberFormatException e) {
            result = "Invalid duration or fee.";
        }
        response.sendRedirect("plans.jsp?msg=" + URLEncoder.encode(result, "UTF-8"));
        return;
    }

    List<String[]> plans = new ArrayList<>();
    String dbError = null;
    String sql = "SELECT p.plan_name, p.duration_months, p.fee, COUNT(m.member_id) " +
                 "FROM Plan p LEFT JOIN Member m ON m.plan_id = p.plan_id " +
                 "GROUP BY p.plan_id, p.plan_name, p.duration_months, p.fee ORDER BY p.duration_months";
    try (Connection con = DBUtil.getConnection();
         Statement st = con.createStatement();
         ResultSet rs = st.executeQuery(sql)) {
        while (rs.next()) {
            plans.add(new String[]{rs.getString(1), rs.getString(2), rs.getString(3), rs.getString(4)});
        }
    } catch (SQLException e) {
        dbError = e.getMessage();
    }
%>
<% String pageTitle = "Plans"; %>
<%@ include file="/WEB-INF/header.jspf" %>
<h1>Membership plans</h1>

<% if (dbError != null) { %>
  <div class="error">Database error: <%= DBUtil.esc(dbError) %></div>
<% } %>

<section class="card">
  <h2>Add a plan</h2>
  <form method="post" action="plans.jsp" class="inline-form">
    <div class="field"><label>Plan name</label><input name="plan_name" required maxlength="40"></div>
    <div class="field"><label>Duration (months)</label><input type="number" name="duration" min="1" max="60" required></div>
    <div class="field"><label>Fee (Rs.)</label><input type="number" name="fee" min="0" step="0.01" required></div>
    <button class="btn" type="submit">Add plan</button>
  </form>
</section>

<section class="card">
  <h2>Available plans</h2>
  <div class="table-wrap">
    <table>
      <tr><th>Plan</th><th>Duration</th><th>Fee</th><th>Members</th></tr>
      <% for (String[] p : plans) { %>
      <tr>
        <td><%= DBUtil.esc(p[0]) %></td>
        <td><%= DBUtil.esc(p[1]) %> month(s)</td>
        <td>Rs. <%= DBUtil.esc(p[2]) %></td>
        <td><%= DBUtil.esc(p[3]) %></td>
      </tr>
      <% } %>
    </table>
  </div>
</section>
