<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="activePage" value="cleaning" scope="request" />
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="success" value="${param.success}" />
<c:set var="errorMsg" value="${requestScope.error}" />
<c:set var="currentUser" value="${sessionScope.loggedInUser}" />
<c:set var="tasks" value="${requestScope.tasks != null ? requestScope.tasks : []}" />
<c:set var="facilities" value="${requestScope.facilities != null ? requestScope.facilities : []}" />
<c:set var="janitors" value="${requestScope.janitors != null ? requestScope.janitors : []}" />
<c:set var="activitiesMap" value="${requestScope.activitiesMap != null ? requestScope.activitiesMap : {}}" />
<c:set var="isJanitor" value="${currentUser != null && currentUser.role.name() == 'janitor'}" />
<c:set var="canCreate" value="${currentUser != null && currentUser.role.name() == 'supervisor'}" />
<c:set var="canDelete" value="${currentUser != null && currentUser.role.name() == 'supervisor'}" />
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cleaning Tasks | SmartCampus</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <style>
        :root { --egerton-green:#00A651; --egerton-green-dark:#008a43; --egerton-gold:#D2AC67;
                --sidebar-bg:#1a472a; --sidebar-hover:#2a5a3a; }
        body { background:#F8F9FC; font-family:'Inter',sans-serif; overflow-x:hidden; }
        .sidebar { background:linear-gradient(180deg,var(--sidebar-bg) 0%,#007624 100%);
                   min-height:100vh; color:white; }
        .nav-link-custom { color:rgba(255,255,255,.85); padding:.7rem 1.2rem; margin:.2rem .8rem;
                           border-radius:12px; transition:all .2s; font-weight:500; font-size:.9rem;
                           display:flex; align-items:center; gap:10px; text-decoration:none; }
        .nav-link-custom:hover { background:var(--sidebar-hover); color:white; }
        .nav-link-custom.active { background:var(--egerton-gold); color:#007624; font-weight:600; }
        .nav-link-custom i { font-size:1.1rem; width:22px; }
        .table-container { background:#fff; border-radius:16px; padding:1.5rem;
                           box-shadow:0 2px 8px rgba(0,0,0,.04); border:1px solid #e9ecef; }
        .badge-status-pending     { background:#fff3e0; color:#92400e; }
        .badge-status-in_progress { background:#dbeafe; color:#1e40af; }
        .badge-status-completed   { background:#d1fae5; color:#065f46; }
        .badge-status-skipped     { background:#f3f4f6; color:#374151; }
        .activity-checklist { list-style:none; padding:0; margin:0.4rem 0 0; font-size:0.8rem; }
        .activity-checklist li { display:flex; align-items:center; gap:6px; padding:3px 0; }
        .activity-checklist li.done label { text-decoration:line-through; color:#6c757d; }
        .activity-checklist input[type="checkbox"] { accent-color:#00A651; cursor:pointer; }
        .activity-checklist label { cursor:pointer; margin:0; }
        @media (max-width: 767.98px) {
            .table-container { padding: 1rem 0.75rem; border-radius:12px; }
            h1 { font-size:1.4rem !important; }
        }
    </style>
</head>
<body>
<div class="container-fluid">
  <div class="row">
    <jsp:include page="/WEB-INF/views/shared/sidebar.jsp"/>
    <main class="col-md-10 ms-sm-auto col-lg-10 px-4 py-4">
      <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
          <h1 style="font-family:'Playfair Display',serif;font-size:1.8rem;">Cleaning Tasks</h1>
          <p class="text-muted small mb-0">Schedule and track cleaning activities</p>
        </div>
        <c:if test="${canCreate}">
        <button class="btn btn-success" data-bs-toggle="modal" data-bs-target="#newTaskModal">
          <i class="bi bi-plus-circle-fill me-1"></i> Schedule Task
        </button>
        </c:if>
      </div>

      <c:if test="${success != null}">
      <div class="alert alert-success alert-dismissible fade show">
        <i class="bi bi-check-circle-fill me-2"></i>Operation completed successfully.
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
      </div>
      </c:if>
      <c:if test="${errorMsg != null}">
      <div class="alert alert-danger alert-dismissible fade show">
        <i class="bi bi-exclamation-triangle-fill me-2"></i>${errorMsg}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
      </div>
      </c:if>

      <div class="table-container">
        <c:if test="${fn:length(tasks) == 0}">
        <p class="text-muted text-center py-4">No cleaning tasks found.</p>
        </c:if>
        <c:if test="${fn:length(tasks) > 0}">
        <div class="table-responsive">
          <table class="table table-hover align-middle">
            <thead class="table-light">
              <tr>
                <th>Facility</th>
                <th>Assigned To</th>
                <th>Scheduled Date</th>
                <th>Status</th>
                <th>Notes</th>
                <c:if test="${isJanitor}"><th>Activities</th></c:if>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <c:forEach var="t" items="${tasks}">
                <c:set var="acts" value="${activitiesMap[t.id] != null ? activitiesMap[t.id] : []}" />
              <tr>
                <td class="fw-medium">${t.facilityName}</td>
                <td class="text-muted small">${t.assignedToName}</td>
                <td class="text-muted small">${t.scheduledDate}</td>
                <td><span class="badge rounded-pill badge-status-${t.status.name()} text-capitalize">${fn:replace(t.status.name(), '_', ' ')}</span></td>
                <td class="text-muted small">${t.notes != null ? t.notes : ''}</td>
                <c:if test="${isJanitor}">
                <td>
                  <c:if test="${fn:length(acts) == 0}">
                  <span class="text-muted small">—</span>
                  </c:if>
                  <c:if test="${fn:length(acts) > 0}">
                    <c:set var="dustOnly" value="${fn:length(acts) == 1}" />
                  <div class="small text-muted mb-1">
                    <c:choose><c:when test="${dustOnly}">Dust only</c:when><c:otherwise>Full clean</c:otherwise></c:choose>
                  </div>
                  <ul class="activity-checklist">
                    <c:forEach var="act" items="${acts}">
                    <li class="${act.done ? 'done' : ''}">
                      <form method="post" action="${ctx}/cleaning-tasks" style="display:contents;">
                        <input type="hidden" name="action" value="completeActivity">
                        <input type="hidden" name="activityId" value="${act.id}">
                        <input type="hidden" name="done" value="${act.done ? 'false' : 'true'}">
                        <input type="checkbox" id="ta${act.id}"
                               <c:if test="${act.done}">checked</c:if>
                               onchange="this.form.submit()">
                        <label for="ta${act.id}">${act.activity}</label>
                      </form>
                    </li>
                    </c:forEach>
                  </ul>
                  </c:if>
                </td>
                </c:if>
                <td>
                  <form method="post" action="${ctx}/cleaning-tasks" class="d-flex gap-1">
                    <input type="hidden" name="action" value="updateStatus">
                    <input type="hidden" name="id" value="${t.id}">
                    <select name="status" class="form-select form-select-sm" style="width:115px;">
                      <option value="pending" <c:if test="${t.status == 'pending'}">selected</c:if>>Pending</option>
                      <option value="in_progress" <c:if test="${t.status == 'in_progress'}">selected</c:if>>In Progress</option>
                      <option value="completed" <c:if test="${t.status == 'completed'}">selected</c:if>>Completed</option>
                      <option value="skipped" <c:if test="${t.status == 'skipped'}">selected</c:if>>Skipped</option>
                    </select>
                    <button class="btn btn-sm btn-primary">Update</button>
                  </form>
                  <c:if test="${canDelete}">
                  <form method="post" action="${ctx}/cleaning-tasks" class="d-inline"
                        onsubmit="return confirm('Delete this task?')">
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="id" value="${t.id}">
                    <button class="btn btn-sm btn-outline-danger"><i class="bi bi-trash-fill"></i></button>
                  </form>
                  </c:if>
                </td>
              </tr>
              </c:forEach>
            </tbody>
          </table>
        </div>
        </c:if>
      </div>
    </main>
  </div>
</div>

<c:if test="${canCreate}">
<!-- New Cleaning Task Modal -->
<div class="modal fade" id="newTaskModal" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <form method="post" action="${ctx}/cleaning-tasks">
        <input type="hidden" name="action" value="create">
        <div class="modal-header">
          <h5 class="modal-title fw-semibold">Schedule Cleaning Task</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <div class="mb-3">
            <label class="form-label fw-semibold small">Facility *</label>
            <select name="facilityId" class="form-select" required>
              <option value="">-- Select Facility --</option>
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
            <input type="date" name="scheduledDate" class="form-control" required id="newTaskDate">
          </div>
          <div class="mb-3">
            <label class="form-label fw-semibold small">Notes</label>
            <textarea name="notes" class="form-control" rows="2" maxlength="500"></textarea>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
          <button type="submit" class="btn btn-success">Schedule Task</button>
        </div>
      </form>
    </div>
  </div>
</div>
</c:if>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
    document.getElementById('newTaskDate').min = new Date().toISOString().split('T')[0];
</script>
</html>
