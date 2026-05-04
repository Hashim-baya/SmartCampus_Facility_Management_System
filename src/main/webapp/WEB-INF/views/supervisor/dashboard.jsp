<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="activePage" value="dashboard" scope="request" />
<c:set var="currentUser" value="${sessionScope.loggedInUser}" />
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="allTasks" value="${requestScope.allTasks != null ? requestScope.allTasks : []}" />
<c:set var="janitors" value="${requestScope.janitors != null ? requestScope.janitors : []}" />
<c:set var="facilities" value="${requestScope.facilities != null ? requestScope.facilities : []}" />
<c:set var="lecturerReports" value="${requestScope.lecturerReports != null ? requestScope.lecturerReports : []}" />
<c:set var="deadlineBreachedMap" value="${requestScope.deadlineBreachedMap != null ? requestScope.deadlineBreachedMap : {}}" />
<c:set var="janitorTotalMap" value="${requestScope.janitorTotalMap != null ? requestScope.janitorTotalMap : {}}" />
<c:set var="janitorCompletedMap" value="${requestScope.janitorCompletedMap != null ? requestScope.janitorCompletedMap : {}}" />
<c:set var="janitorPctMap" value="${requestScope.janitorPctMap != null ? requestScope.janitorPctMap : {}}" />
<c:set var="janitorInitialMap" value="${requestScope.janitorInitialMap != null ? requestScope.janitorInitialMap : {}}" />
<c:set var="reportReportedAtMap" value="${requestScope.reportReportedAtMap != null ? requestScope.reportReportedAtMap : {}}" />
<c:set var="success" value="${param.success}" />
<c:set var="errorMsg" value="${requestScope.error}" />

<c:set var="pendingCount" value="0" />
<c:set var="inProgressCount" value="0" />
<c:set var="completedCount" value="0" />
<c:forEach var="t" items="${allTasks}">
  <c:choose>
    <c:when test="${t.status.name() eq 'pending'}"><c:set var="pendingCount" value="${pendingCount + 1}" /></c:when>
    <c:when test="${t.status.name() eq 'in_progress'}"><c:set var="inProgressCount" value="${inProgressCount + 1}" /></c:when>
    <c:when test="${t.status.name() eq 'completed'}"><c:set var="completedCount" value="${completedCount + 1}" /></c:when>
  </c:choose>
</c:forEach>
<c:set var="overdueCount" value="${requestScope.overdueCount != null ? requestScope.overdueCount : 0}" />
<c:set var="activeAlerts" value="${inProgressCount + overdueCount}" />
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Supervisor Dashboard | SmartCampus - Egerton University</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;800&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        :root {
            --egerton-green: #00A651;
            --egerton-green-dark: #008a43;
            --egerton-green-deep: #007624;
            --egerton-gold: #D2AC67;
            --bg-light: #F8F9FC;
            --card-white: #ffffff;
            --text-dark: #1F2A3A;
            --text-muted: #5a6e8a;
            --border-color: #e9ecef;
            --sidebar-bg: #1a472a;
            --sidebar-hover: #2a5a3a;
            --high-intensity-bg: #fee2e2;
            --high-intensity-color: #e74c3c;
            --low-intensity-bg: #e0f2e9;
            --low-intensity-color: #00A651;
            --pending-bg: #fff3e0;
            --pending-color: #e67e22;
            --completed-bg: #e0f2e9;
            --completed-color: #00A651;
            --alert-bg: #fee2e2;
            --alert-color: #e74c3c;
        }

        body { background: var(--bg-light); font-family: 'Inter', sans-serif; overflow-x: hidden; }

        .sidebar { background: linear-gradient(180deg, var(--sidebar-bg) 0%, var(--egerton-green-deep) 100%);
                   min-height: 100vh; color: white; box-shadow: 2px 0 12px rgba(0,0,0,0.08); }
        .nav-link-custom { color: rgba(255,255,255,0.85); padding: 0.7rem 1.2rem; margin: 0.2rem 0.8rem;
                           border-radius: 12px; transition: all 0.2s; font-weight: 500; font-size: 0.9rem;
                           display: flex; align-items: center; gap: 10px; text-decoration: none; }
        .nav-link-custom:hover { background: var(--sidebar-hover); color: white; transform: translateX(4px); }
        .nav-link-custom.active { background: var(--egerton-gold); color: var(--egerton-green-deep); font-weight: 600; }
        .nav-link-custom i { font-size: 1.2rem; width: 24px; }

        .main-content { padding: 1.5rem 2rem; }

        .welcome-header h1 { font-family: 'Playfair Display', serif; font-size: 1.8rem; font-weight: 700; color: var(--text-dark); }
        .welcome-header p { color: var(--text-muted); font-size: 0.85rem; }

        .stat-card { background: var(--card-white); border-radius: 20px; padding: 1.2rem;
                     box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color);
                     transition: transform 0.2s, box-shadow 0.2s, border-color 0.2s; text-align: center;
                     cursor: pointer; }
        .stat-card:hover { transform: translateY(-3px); box-shadow: 0 6px 16px rgba(0,166,81,0.12); }
        .stat-card.stat-active { border-color: var(--egerton-green); box-shadow: 0 0 0 3px rgba(0,166,81,0.18); transform: translateY(-3px); }
        .stat-icon { width: 48px; height: 48px;
                     background: linear-gradient(135deg, rgba(0,166,81,0.1), rgba(210,172,103,0.1));
                     border-radius: 16px; display: flex; align-items: center; justify-content: center;
                     margin: 0 auto 0.8rem; }
        .stat-icon i { font-size: 1.8rem; color: var(--egerton-green); }
        .stat-card h3 { font-size: 1.8rem; font-weight: 700; margin-bottom: 0; }
        .stat-card p { color: var(--text-muted); font-size: 0.75rem; margin-bottom: 0; }

        .alert-card { background: var(--alert-bg); border-left: 4px solid var(--alert-color);
                      border-radius: 12px; padding: 1rem; margin-bottom: 1rem; }

        .table-container { background: var(--card-white); border-radius: 20px; padding: 1.5rem;
                           box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color); }

        .table-custom { margin-bottom: 0; }
        .table-custom thead { background: #F8F9FC; }
        .table-custom th { font-weight: 600; font-size: 0.8rem; color: var(--text-muted); padding: 0.8rem; }
        .table-custom td { font-size: 0.85rem; padding: 0.8rem; vertical-align: middle; }

        .status-completed { background: var(--completed-bg); color: var(--completed-color);
                            padding: 4px 10px; border-radius: 20px; font-size: 0.7rem; font-weight: 600; }
        .status-pending   { background: var(--pending-bg); color: var(--pending-color);
                            padding: 4px 10px; border-radius: 20px; font-size: 0.7rem; font-weight: 600; }
        .status-progress  { background: #e3f2fd; color: #1976d2;
                            padding: 4px 10px; border-radius: 20px; font-size: 0.7rem; font-weight: 600; }
        .status-skipped   { background: #f3f4f6; color: #374151;
                            padding: 4px 10px; border-radius: 20px; font-size: 0.7rem; font-weight: 600; }

        .progress-bar-custom { width: 60px; height: 6px; background: var(--border-color);
                               border-radius: 3px; overflow: hidden; }
        .progress-fill { height: 100%; background: var(--egerton-green); border-radius: 3px; }

        .btn-reassign { background: var(--egerton-gold); color: var(--egerton-green-deep); border: none;
                        padding: 4px 12px; border-radius: 20px; font-size: 0.7rem; font-weight: 600; transition: all 0.2s; }
        .btn-reassign:hover { background: var(--egerton-green); color: white; }

        .task-item { padding: 12px 0; border-bottom: 1px solid var(--border-color); }
        .task-item:last-child { border-bottom: none; }
        .task-content { flex: 1; }

        .janitor-card { background: var(--card-white); border-radius: 16px; padding: 1rem;
                        border: 1px solid var(--border-color); transition: all 0.2s; }
        .janitor-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
        .janitor-avatar { width: 48px; height: 48px;
                          background: linear-gradient(135deg, var(--egerton-green), var(--egerton-gold));
                          border-radius: 50%; display: flex; align-items: center; justify-content: center;
                          color: white; font-weight: bold; font-size: 1.2rem; }
        .janitor-progress { width: 100%; height: 6px; background: var(--border-color);
                            border-radius: 3px; overflow: hidden; margin-top: 0.5rem; }
        .janitor-progress-fill { height: 100%; background: var(--egerton-green); border-radius: 3px; }

        @keyframes slideIn  { from { transform: translateX(100%); opacity: 0; } to { transform: translateX(0); opacity: 1; } }
        @keyframes slideOut { from { transform: translateX(0); opacity: 1; } to { transform: translateX(100%); opacity: 0; } }
        .custom-toast { position: fixed; bottom: 20px; right: 20px; padding: 12px 20px; border-radius: 12px;
                        font-size: 0.85rem; font-weight: 500; z-index: 9999; animation: slideIn 0.3s ease;
                        cursor: pointer; display: flex; align-items: center; gap: 8px; }

        .modal-custom .modal-content { border-radius: 24px; border: none; }
        .modal-custom .modal-header { background: linear-gradient(135deg, var(--egerton-green-dark), var(--egerton-green));
                                      color: white; border-radius: 24px 24px 0 0; }

        @media (max-width: 767.98px) {
            .main-content { padding: 1rem; }
            .welcome-header h1 { font-size: 1.3rem; }
            .stat-card { padding: 1rem; }
            .table-container { padding: 1rem 0.75rem; border-radius: 14px; }
            .janitor-card { padding: 0.75rem; }
        }
    </style>
</head>
<body>
<div class="container-fluid">
  <div class="row">
    <jsp:include page="/WEB-INF/views/shared/sidebar.jsp"/>

    <div class="col-md-10 ms-sm-auto col-lg-10 main-content">

      <!-- Welcome Header -->
      <div class="welcome-header d-flex justify-content-between align-items-center mb-4">
        <div>
          <h1>Supervisor Dashboard</h1>
          <p>Monitor and manage cleaning operations</p>
        </div>
        <div class="d-flex align-items-center gap-2">
          <button class="btn btn-success" data-bs-toggle="modal" data-bs-target="#assignOfficeModal">
            <i class="bi bi-plus-circle-fill me-1"></i> Assign Office
          </button>
          <span class="badge bg-light text-dark p-2 shadow-sm">
            <i class="bi bi-person-circle"></i> Supervisor &nbsp;|&nbsp; ${currentUser.email}
          </span>
        </div>
      </div>
      
        <c:if test="${success != null}">
          <c:set var="successMsg">
            <c:choose>
              <c:when test="${success == 'assigned'}">Office assigned to janitor successfully.</c:when>
              <c:when test="${success == 'reassigned'}">Task reassigned successfully.</c:when>
              <c:otherwise>Operation completed successfully.</c:otherwise>
            </c:choose>
          </c:set>
          <div class="alert alert-success alert-dismissible fade show">
            <i class="bi bi-check-circle-fill me-2"></i>${successMsg}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
          </div>
        </c:if>
        <c:if test="${errorMsg != null}">
          <div class="alert alert-danger alert-dismissible fade show">
            <i class="bi bi-exclamation-triangle-fill me-2"></i>${errorMsg}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
          </div>
        </c:if>

      <!-- Dashboard Section -->
      <div id="dashboardSection">

        <!-- Stats Cards -->
        <div class="row mb-4">
            <div class="col-6 col-md-3 mb-3 mb-md-0">
              <div class="stat-card" data-nav="monitor" data-filter="completed" title="Click to view completed tasks">
                <div class="stat-icon"><i class="bi bi-check2-circle"></i></div>
                <h3>${completedCount}</h3>
                <p>Completed</p>
              </div>
            </div>
            <div class="col-6 col-md-3 mb-3 mb-md-0">
              <div class="stat-card" data-nav="reports" title="Click to view dispute reports">
                <div class="stat-icon"><i class="bi bi-exclamation-triangle"></i></div>
                <h3>${fn:length(lecturerReports)}</h3>
                <p>Disputed</p>
              </div>
            </div>
            <div class="col-6 col-md-3">
              <div class="stat-card" data-nav="monitor" data-filter="in_progress" title="Click to view in-progress tasks">
                <div class="stat-icon"><i class="bi bi-bell"></i></div>
                <h3>${activeAlerts}</h3>
                <p>Active Alerts</p>
              </div>
            </div>
            <div class="col-6 col-md-3">
              <div class="stat-card" data-nav="monitor" data-filter="pending" title="Click to view pending tasks">
                <div class="stat-icon"><i class="bi bi-hourglass-split"></i></div>
                <h3>${pendingCount}</h3>
                <p>Pending</p>
              </div>
            </div>
        </div>

        <!-- Incomplete Task Alert -->
        <c:if test="${inProgressCount > 0}">
          <div class="alert-card mb-4">
            <div class="d-flex align-items-center gap-2">
              <i class="bi bi-clock-history text-danger fs-4"></i>
              <div>
                <strong>Incomplete Task Alert</strong><br>
                <small>${inProgressCount} task${inProgressCount == 1 ? '' : 's'} currently in progress</small>
              </div>
            </div>
          </div>
        </c:if>

        <c:if test="${overdueCount > 0}">
          <div class="alert-card mb-4">
            <div class="d-flex align-items-center gap-2">
              <i class="bi bi-alarm text-danger fs-4"></i>
              <div>
                <strong>Deadline Alert</strong><br>
                <small>${overdueCount} task${overdueCount == 1 ? '' : 's'} missed the 8:00 AM cleaning deadline</small>
              </div>
            </div>
          </div>
        </c:if>

        <!-- Pending Tasks Summary -->
        <div class="table-container">
          <h5><i class="bi bi-list-check text-success"></i> Pending Tasks Summary</h5>
          <p class="text-muted small">Tasks awaiting completion</p>
          <c:choose>
            <c:when test="${pendingCount + inProgressCount == 0}">
              <div class="text-center py-4 text-muted">No pending tasks</div>
            </c:when>
            <c:otherwise>
              <c:forEach var="t" items="${allTasks}">
                <c:if test="${t.status.name() eq 'pending' || t.status.name() eq 'in_progress'}">
                  <c:set var="statusClass" value="${t.status.name() eq 'in_progress' ? 'status-progress' : 'status-pending'}" />
                  <c:set var="statusText" value="${t.status.name() eq 'in_progress' ? 'In Progress' : 'Pending'}" />
                  <div class="task-item d-flex align-items-center gap-2">
                    <div class="task-content">
                      <div class="d-flex justify-content-between align-items-center mb-1">
                        <strong>${t.facilityName}</strong>
                        <div class="d-flex align-items-center gap-2 flex-wrap justify-content-end">
                          <c:if test="${deadlineBreachedMap[t.id]}">
                            <span class="status-skipped">Past 8:00 AM</span>
                          </c:if>
                          <span class="${statusClass}">${statusText}</span>
                        </div>
                      </div>
                      <div class="d-flex justify-content-between align-items-center">
                        <small class="text-muted">Scheduled: ${t.scheduledDate}</small>
                        <small class="text-muted">Assigned: ${empty t.assignedToName ? 'Unassigned' : t.assignedToName}</small>
                      </div>
                    </div>
                  </div>
                </c:if>
              </c:forEach>
            </c:otherwise>
          </c:choose>
        </div>
      </div>

      <!-- Live Monitor Section -->
      <div id="monitorSection" style="display:none;">
        <div class="table-container">
          <div class="d-flex flex-wrap justify-content-between align-items-center mb-3">
            <div>
              <h5 class="mb-0"><i class="bi bi-tv text-success"></i> Live Task Monitor</h5>
              <p class="text-muted small mb-0">Real-time tracking of all cleaning tasks</p>
            </div>
            <div class="d-flex flex-wrap gap-2 mt-2 mt-md-0" id="monitorFilterBar">
              <button class="btn btn-sm btn-success" data-status-filter="all"><i class="bi bi-grid"></i> All</button>
              <button class="btn btn-sm btn-outline-secondary" data-status-filter="completed"><i class="bi bi-check2-circle"></i> Completed</button>
              <button class="btn btn-sm btn-outline-secondary" data-status-filter="in_progress"><i class="bi bi-hourglass-split"></i> In Progress</button>
              <button class="btn btn-sm btn-outline-secondary" data-status-filter="pending"><i class="bi bi-clock"></i> Pending</button>
            </div>
          </div>
          <c:choose>
            <c:when test="${empty allTasks}">
              <div class="text-center py-4 text-muted">No tasks found</div>
            </c:when>
            <c:otherwise>
          <div class="table-responsive">
            <table class="table table-custom align-middle">
              <thead>
                <tr>
                  <th>Office</th>
                  <th>Status</th>
                  <th>Scheduled Date</th>
                  <th>Assigned Janitor</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody id="monitorTableBody">
                <c:forEach var="t" items="${allTasks}">
                  <c:set var="ds" value="${t.status.name()}" />
                  <c:set var="sc" value="status-pending" />
                  <c:set var="sl" value="Pending" />
                  <c:choose>
                    <c:when test="${ds eq 'completed'}">
                      <c:set var="sc" value="status-completed" />
                      <c:set var="sl" value="Completed" />
                    </c:when>
                    <c:when test="${ds eq 'in_progress'}">
                      <c:set var="sc" value="status-progress" />
                      <c:set var="sl" value="In Progress" />
                    </c:when>
                    <c:when test="${ds eq 'skipped'}">
                      <c:set var="sc" value="status-skipped" />
                      <c:set var="sl" value="Skipped" />
                    </c:when>
                  </c:choose>

                  <tr data-status="${ds}">
                    <td><strong>${t.facilityName}</strong></td>
                    <td>
                      <div class="d-flex flex-column gap-1">
                        <c:if test="${deadlineBreachedMap[t.id]}">
                          <span class="status-skipped">Past 8:00 AM</span>
                        </c:if>
                        <span class="${sc}">${sl}</span>
                      </div>
                    </td>
                    <td>${t.scheduledDate}</td>
                    <td>${empty t.assignedToName ? 'Unassigned' : t.assignedToName}</td>
                    <td>
                      <button class="btn-reassign"
                        data-task-id="${t.id}"
                        data-office-name="${t.facilityName}"
                        data-current-janitor-id="${t.assignedTo}">
                        <i class="bi bi-arrow-repeat"></i> Reassign
                      </button>
                    </td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
          <div id="monitorNoResults" class="text-center py-3 text-muted d-none">No tasks match the selected filter.</div>
            </c:otherwise>
          </c:choose>
        </div>
      </div>

      <!-- Janitor Staff Section -->
      <div id="staffSection" style="display:none;">
        <c:choose>
          <c:when test="${empty janitors}">
            <div class="text-center py-5 text-muted">No janitors found</div>
          </c:when>
          <c:otherwise>
            <div class="row">
              <c:forEach var="j" items="${janitors}">
                <c:set var="jCompleted" value="${janitorCompletedMap[j.id] != null ? janitorCompletedMap[j.id] : 0}" />
                <c:set var="jTotal" value="${janitorTotalMap[j.id] != null ? janitorTotalMap[j.id] : 0}" />
                <c:set var="jPct" value="${janitorPctMap[j.id] != null ? janitorPctMap[j.id] : 0}" />
                <div class="col-md-4 mb-3">
                  <div class="janitor-card">
                    <div class="d-flex align-items-center gap-3">
                      <div class="janitor-avatar">${janitorInitialMap[j.id] != null ? janitorInitialMap[j.id] : 'J'}</div>
                      <div>
                        <h6 class="mb-0">${j.name}</h6>
                        <small class="text-muted">${j.email}</small>
                      </div>
                    </div>
                    <div class="mt-3">
                      <div class="d-flex justify-content-between mb-1">
                        <small>Task Completion</small>
                        <small>${jCompleted}/${jTotal}</small>
                      </div>
                      <div class="janitor-progress">
                        <div class="janitor-progress-fill" style="width:${jPct}%"></div>
                      </div>
                    </div>
                  </div>
                </div>
              </c:forEach>
            </div>
          </c:otherwise>
        </c:choose>
      </div>

      <!-- Dispute Reports Section -->
      <div id="reportsSection" style="display:none;">
        <div class="table-container">
          <h5><i class="bi bi-flag text-success"></i> Dispute Reports</h5>
          <p class="text-muted small">Reports filed by lecturers regarding cleaning quality</p>
          <c:choose>
            <c:when test="${empty lecturerReports}">
              <div class="text-center py-4 text-muted">No dispute reports</div>
            </c:when>
            <c:otherwise>
              <div class="table-responsive">
                <table class="table table-custom align-middle">
                  <thead>
                    <tr>
                      <th>Lecturer</th>
                      <th>Task / Office</th>
                      <th>Rating</th>
                      <th>Reason</th>
                      <th>Notes</th>
                      <th>Reported At</th>
                    </tr>
                  </thead>
                  <tbody>
                    <c:forEach var="r" items="${lecturerReports}">
                      <tr>
                        <td><strong>${empty r.lecturerName ? 'Unknown' : r.lecturerName}</strong></td>
                        <td>
                          <div>${r.taskName}</div>
                          <c:if test="${not empty r.activityName}">
                            <small class="text-muted">${r.activityName}</small>
                          </c:if>
                        </td>
                        <td>
                          <c:forEach begin="1" end="5" var="s">
                            <c:choose>
                              <c:when test="${s <= r.rating}"><i class="bi bi-star-fill" style="color:#f0a500;font-size:0.85rem;"></i></c:when>
                              <c:otherwise><i class="bi bi-star" style="color:#ccc;font-size:0.85rem;"></i></c:otherwise>
                            </c:choose>
                          </c:forEach>
                          <small class="ms-1 text-muted">(${r.rating}/5)</small>
                        </td>
                        <td style="max-width:220px;"><small>${r.reason}</small></td>
                        <td style="max-width:160px;"><small>${empty r.notes ? '—' : r.notes}</small></td>
                        <td><small>${empty reportReportedAtMap[r.id] ? '—' : reportReportedAtMap[r.id]}</small></td>
                      </tr>
                    </c:forEach>
                  </tbody>
                </table>
              </div>
            </c:otherwise>
          </c:choose>
        </div>
      </div>

    </div>
  </div>
</div>

<!-- Assign Office Modal -->
<div class="modal fade modal-custom" id="assignOfficeModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <form method="post" action="${ctx}/cleaning-tasks">
        <input type="hidden" name="action" value="create">
        <div class="modal-header">
          <h5 class="modal-title"><i class="bi bi-plus-circle-fill"></i> Assign Office for Cleaning</h5>
          <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <div class="mb-3">
            <label class="form-label fw-semibold small">Office / Facility *</label>
            <select name="facilityId" class="form-select" required>
              <option value="">-- Select Office --</option>
              <c:forEach var="f" items="${facilities}">
                <option value="${f.id}">${f.name}</option>
              </c:forEach>
            </select>
          </div>
          <div class="mb-3">
            <label class="form-label fw-semibold small">Assign To (Janitor) *</label>
            <select name="janitorId" class="form-select" required>
              <option value="">-- Select Janitor --</option>
              <c:forEach var="j" items="${janitors}">
                <option value="${j.id}">${j.name}</option>
              </c:forEach>
            </select>
          </div>
          <div class="mb-3">
            <label class="form-label fw-semibold small">Scheduled Date *</label>
            <input type="date" name="scheduledDate" class="form-control" required id="assignOfficeDate">
          </div>
          <div class="mb-3">
            <label class="form-label fw-semibold small">Notes</label>
            <textarea name="notes" class="form-control" rows="2" maxlength="500"></textarea>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
          <button type="submit" class="btn btn-success">Assign Office</button>
        </div>
      </form>
    </div>
  </div>
</div>

<!-- Reassign Modal -->
<div class="modal fade modal-custom" id="reassignModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <form method="post" action="${ctx}/cleaning-tasks" id="reassignForm">
        <input type="hidden" name="action" value="reassign">
        <input type="hidden" name="id" id="reassignTaskId">
        <div class="modal-header">
          <h5 class="modal-title"><i class="bi bi-arrow-repeat"></i> Reassign Task</h5>
          <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <p>Reassign <strong id="reassignOfficeName"></strong> to:</p>
          <select name="janitorId" id="reassignJanitorSelect" class="form-select">
            <c:forEach var="j" items="${janitors}">
              <option value="${j.id}">${j.name}</option>
            </c:forEach>
          </select>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
          <button type="submit" class="btn btn-primary">Reassign</button>
        </div>
      </form>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
    document.getElementById('assignOfficeDate').min = new Date().toISOString().split('T')[0];

    function showToast(message, type) {
        const toastDiv = document.createElement('div');
        toastDiv.className = 'custom-toast';
        toastDiv.style.backgroundColor = type === 'success' ? '#00A651' : (type === 'error' ? '#dc3545' : '#17a2b8');
        toastDiv.style.color = 'white';
        const icon = type === 'success' ? '<i class="bi bi-check-circle-fill"></i>' :
                     type === 'error'   ? '<i class="bi bi-exclamation-triangle-fill"></i>' :
                                          '<i class="bi bi-info-circle-fill"></i>';
        toastDiv.innerHTML = icon + '<span>' + message + '</span>';
        document.body.appendChild(toastDiv);
        setTimeout(() => { toastDiv.style.animation = 'slideOut 0.3s ease'; setTimeout(() => toastDiv.remove(), 300); }, 3000);
        toastDiv.onclick = () => { toastDiv.style.animation = 'slideOut 0.3s ease'; setTimeout(() => toastDiv.remove(), 300); };
    }

    function openReassignModal(btn) {
        const taskId         = btn.getAttribute('data-task-id');
        const officeName     = btn.getAttribute('data-office-name');
        const currentJanitorId = btn.getAttribute('data-current-janitor-id');
        document.getElementById('reassignTaskId').value    = taskId;
        document.getElementById('reassignOfficeName').textContent = officeName;
        const select = document.getElementById('reassignJanitorSelect');
        if (select && currentJanitorId) {
            for (let i = 0; i < select.options.length; i++) {
                if (select.options[i].value === currentJanitorId) {
                    select.selectedIndex = i;
                    break;
                }
            }
        }
        new bootstrap.Modal(document.getElementById('reassignModal')).show();
    }

    // ── Section navigation ──────────────────────────────────────────────────
    function navigateToSection(section, statusFilter) {
        const sections = { dashboard: 'dashboardSection', monitor: 'monitorSection', staff: 'staffSection', reports: 'reportsSection' };
        Object.values(sections).forEach(id => {
            const el = document.getElementById(id);
            if (el) el.style.display = 'none';
        });
        const target = sections[section];
        if (target) document.getElementById(target).style.display = 'block';

        // Update active state on all nav links (desktop + mobile drawer)
        document.querySelectorAll('.nav-link-custom').forEach(l => l.classList.remove('active'));
        document.querySelectorAll('.nav-link-custom[data-section="' + section + '"]').forEach(l => l.classList.add('active'));

        // Update active state on stat cards
        document.querySelectorAll('.stat-card[data-nav]').forEach(c => c.classList.remove('stat-active'));
        if (statusFilter) {
            document.querySelectorAll('.stat-card[data-nav="' + section + '"][data-filter="' + statusFilter + '"]')
                    .forEach(c => c.classList.add('stat-active'));
        }

        if (section === 'monitor') {
            applyMonitorFilter(statusFilter || 'all');
        }
    }

    // ── Monitor filter ──────────────────────────────────────────────────────
    function applyMonitorFilter(filter) {
        const tbody = document.getElementById('monitorTableBody');
        const noResults = document.getElementById('monitorNoResults');
        if (!tbody) return;

        let visible = 0;
        tbody.querySelectorAll('tr').forEach(row => {
            const status = row.getAttribute('data-status');
            const show = (filter === 'all' || status === filter);
            row.style.display = show ? '' : 'none';
            if (show) visible++;
        });

        if (noResults) noResults.classList.toggle('d-none', visible > 0);

        // Highlight active filter button
        document.querySelectorAll('[data-status-filter]').forEach(btn => {
            const active = btn.getAttribute('data-status-filter') === filter;
            btn.classList.toggle('btn-success', active);
            btn.classList.toggle('btn-outline-secondary', !active);
        });
    }

    // ── Event delegation (reassign + filter buttons) ───────────────────────
    document.addEventListener('click', e => {
        const reassignBtn = e.target.closest('.btn-reassign');
        if (reassignBtn) { openReassignModal(reassignBtn); return; }

        const filterBtn = e.target.closest('[data-status-filter]');
        if (filterBtn) { applyMonitorFilter(filterBtn.getAttribute('data-status-filter')); return; }
    });

    // ── Sidebar / mobile-drawer section links ──────────────────────────────
    document.querySelectorAll('.nav-link-custom[data-section]').forEach(link => {
        link.addEventListener('click', e => {
            e.preventDefault();
            navigateToSection(link.getAttribute('data-section'));
        });
    });

    // ── Stat card click → navigate to respective section ───────────────────
    document.querySelectorAll('.stat-card[data-nav]').forEach(card => {
        card.addEventListener('click', function () {
            navigateToSection(this.getAttribute('data-nav'), this.getAttribute('data-filter') || null);
        });
    });
</script>
</body>
</html>
