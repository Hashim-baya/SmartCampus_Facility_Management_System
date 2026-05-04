<%@ page contentType="text/html;charset=UTF-8" language="java" isErrorPage="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Error | SmartCampus</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
</head>
<body class="d-flex align-items-center justify-content-center min-vh-100 bg-light">
  <div class="text-center p-5">
    <div style="font-size:4rem;color:#dc3545;"><i class="bi bi-exclamation-triangle-fill"></i></div>
    <h1 class="fw-bold mt-3">Something went wrong</h1>
    <p class="text-muted mt-2"><c:out value="${empty error ? 'An unexpected error occurred.' : error}" /></p>
    <a href="${pageContext.request.contextPath}/login" class="btn btn-success mt-3">
      <i class="bi bi-arrow-left me-1"></i> Back to Login
    </a>
  </div>
</body>
</html>
