package com.smartcampus.servlet;

import com.smartcampus.dao.FacilityDAO;
import com.smartcampus.dao.JanitorReportDAO;
import com.smartcampus.dao.LecturerCheckinDAO;
import com.smartcampus.dao.TaskActivityDAO;
import com.smartcampus.dao.UserDAO;
import com.smartcampus.dao.CleaningTaskDAO;
import com.smartcampus.model.CleaningTask;
import com.smartcampus.model.Facility;
import com.smartcampus.model.TaskActivity;
import com.smartcampus.model.User;
import com.smartcampus.util.CampusCalendarUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Resolves the dashboard URL for the currently logged-in user's role and
 * pre-loads summary statistics before forwarding to the appropriate JSP.
 * Mapped to /admin/dashboard, /lecturer/dashboard, /janitor/dashboard,
 * /supervisor/dashboard in web.xml.
 */
public class DashboardServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(DashboardServlet.class.getName());

    private final UserDAO                userDAO     = new UserDAO();
    private final FacilityDAO            facDAO      = new FacilityDAO();
    private final CleaningTaskDAO        ctDAO       = new CleaningTaskDAO();
    private final JanitorReportDAO       reportDAO   = new JanitorReportDAO();
    private final TaskActivityDAO        activityDAO = new TaskActivityDAO();
    private final LecturerCheckinDAO     checkinDAO  = new LecturerCheckinDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("loggedInUser") == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        User user = (User) session.getAttribute("loggedInUser");
        String jspPath;

        try {
            switch (user.getRole()) {
                case admin:
                    req.setAttribute("totalUsers",       userDAO.count());
                    req.setAttribute("totalFacilities",  facDAO.count());
                    req.setAttribute("pendingRequests",  ctDAO.countByStatus(CleaningTask.Status.pending));
                    req.setAttribute("activeFacilities", facDAO.countByStatus(Facility.Status.available));
                    req.setAttribute("completedToday",   ctDAO.countCompletedToday());
                    req.setAttribute("allUsers",         userDAO.findAll());
                    req.setAttribute("allFacilities",    facDAO.findAll());
                    jspPath = "/WEB-INF/views/admin/dashboard.jsp";
                    break;
                case lecturer:
                    Facility assignedOffice = facDAO.findByLecturerId(user.getId());
                    req.setAttribute("assignedOffice", assignedOffice);
                    LocalDate today = LocalDate.now();
                    boolean workingDay = CampusCalendarUtil.isWorkingDay(today);
                    req.setAttribute("workingDay", workingDay);
                    req.setAttribute("calendarNotice", CampusCalendarUtil.getDayNotice(today));
                    boolean checkedInToday = false;
                    if (assignedOffice != null && workingDay) {
                        checkedInToday = checkinDAO.hasCheckedIn(
                                user.getId(), assignedOffice.getId(), today);
                    }
                    req.setAttribute("checkedInToday", checkedInToday);
                    List<CleaningTask> officeTasks = new ArrayList<>();
                    if (assignedOffice != null && workingDay) {
                        for (CleaningTask task : ctDAO.findByDate(today)) {
                            if (task.getFacilityId() == assignedOffice.getId()) {
                                officeTasks.add(task);
                            }
                        }
                    }
                    req.setAttribute("officeTasks", officeTasks);
                    Map<Integer, List<TaskActivity>> lecturerActivitiesMap = new LinkedHashMap<>();
                    for (CleaningTask task : officeTasks) {
                        lecturerActivitiesMap.put(task.getId(), activityDAO.findOrGenerateForTask(task));
                    }
                    req.setAttribute("activitiesMap", lecturerActivitiesMap);
                    req.setAttribute("facilities",    facDAO.findByStatus(Facility.Status.available));
                    jspPath = "/WEB-INF/views/lecturer/dashboard.jsp";
                    break;
                case janitor:
                    List<CleaningTask> myTasks = ctDAO.findByJanitor(user.getId());
                    req.setAttribute("myTasks",    myTasks);
                    req.setAttribute("todayCount", ctDAO.countTodayByJanitor(user.getId()));

                    // Pre-load (and auto-generate) activity checklists for each task
                    Map<Integer, List<TaskActivity>> janitorActivitiesMap = new LinkedHashMap<>();
                    for (CleaningTask t : myTasks) {
                        janitorActivitiesMap.put(t.getId(), activityDAO.findOrGenerateForTask(t));
                    }
                    req.setAttribute("activitiesMap", janitorActivitiesMap);
                    jspPath = "/WEB-INF/views/janitor/dashboard.jsp";
                    break;
                case supervisor:
                    List<CleaningTask> allTasksSupervisor = ctDAO.findAll();
                    List<User> janitorsSupervisor = userDAO.findByRole(User.Role.janitor);
                    var lecturerReportsSupervisor = reportDAO.findAll();

                    // Deadline logic: used by supervisor views to show "Past 8:00 AM" badges
                    LocalDate todaySupervisor = LocalDate.now();
                    boolean afterDeadlineSupervisor = LocalTime.now().isAfter(LocalTime.of(8, 0));

                    Map<Integer, Boolean> deadlineBreachedMap = new LinkedHashMap<>();
                    int overdueCountSupervisor = 0;
                    for (CleaningTask t : allTasksSupervisor) {
                        boolean deadlineBreached = afterDeadlineSupervisor
                                && t.getScheduledDate() != null
                                && !t.getScheduledDate().isAfter(todaySupervisor)
                                && t.getStatus() != CleaningTask.Status.completed;
                        deadlineBreachedMap.put(t.getId(), deadlineBreached);
                        if (deadlineBreached) overdueCountSupervisor++;
                    }

                    // Janitor performance summaries (task totals + completion %)
                    Map<Integer, Long> janitorTotalMap = new LinkedHashMap<>();
                    Map<Integer, Long> janitorCompletedMap = new LinkedHashMap<>();
                    Map<Integer, Integer> janitorPctMap = new LinkedHashMap<>();
                    Map<Integer, String> janitorInitialMap = new LinkedHashMap<>();

                    for (User j : janitorsSupervisor) {
                        janitorTotalMap.put(j.getId(), 0L);
                        janitorCompletedMap.put(j.getId(), 0L);
                        String name = j.getName();
                        String initial = (name != null && !name.isBlank())
                                ? String.valueOf(Character.toUpperCase(name.charAt(0)))
                                : "J";
                        janitorInitialMap.put(j.getId(), initial);
                    }
                    for (CleaningTask t : allTasksSupervisor) {
                        int janitorId = t.getAssignedTo();
                        if (!janitorTotalMap.containsKey(janitorId)) continue;

                        janitorTotalMap.put(janitorId, janitorTotalMap.get(janitorId) + 1);
                        if (t.getStatus() == CleaningTask.Status.completed) {
                            janitorCompletedMap.put(janitorId, janitorCompletedMap.get(janitorId) + 1);
                        }
                    }
                    for (User j : janitorsSupervisor) {
                        long total = janitorTotalMap.getOrDefault(j.getId(), 0L);
                        long completed = janitorCompletedMap.getOrDefault(j.getId(), 0L);
                        int pct = total > 0 ? (int) ((completed * 100) / total) : 0;
                        janitorPctMap.put(j.getId(), pct);
                    }

                    // Format dispute report timestamps for display (java.time isn't supported by fmt tags)
                    DateTimeFormatter reportDtf = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
                    Map<Integer, String> reportReportedAtMap = new LinkedHashMap<>();
                    for (var r : lecturerReportsSupervisor) {
                        String formatted = (r.getReportedAt() != null) ? reportDtf.format(r.getReportedAt()) : "—";
                        reportReportedAtMap.put(r.getId(), formatted);
                    }

                    req.setAttribute("allTasks", allTasksSupervisor);
                    req.setAttribute("janitors", janitorsSupervisor);
                    req.setAttribute("facilities", facDAO.findAll());
                    req.setAttribute("lecturerReports", lecturerReportsSupervisor);
                    req.setAttribute("deadlineBreachedMap", deadlineBreachedMap);
                    req.setAttribute("overdueCount", overdueCountSupervisor);
                    req.setAttribute("today", todaySupervisor);
                    req.setAttribute("afterDeadline", afterDeadlineSupervisor);
                    req.setAttribute("janitorTotalMap", janitorTotalMap);
                    req.setAttribute("janitorCompletedMap", janitorCompletedMap);
                    req.setAttribute("janitorPctMap", janitorPctMap);
                    req.setAttribute("janitorInitialMap", janitorInitialMap);
                    req.setAttribute("reportReportedAtMap", reportReportedAtMap);
                    jspPath = "/WEB-INF/views/supervisor/dashboard.jsp";
                    break;
                default:
                    resp.sendRedirect(req.getContextPath() + "/login");
                    return;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error loading dashboard data for user " + user.getId(), e);
            req.setAttribute("error", "Failed to load dashboard data. Please try again.");
            jspPath = "/WEB-INF/views/error.jsp";
        }

        req.getRequestDispatcher(jspPath).forward(req, resp);
    }
}
