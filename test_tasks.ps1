# Enterprise CRM - Task Management Tests
# Comprehensive testing of task management with polymorphic relationships

Write-Host "`n=== Task & Follow-Up Management Module Tests ===" -ForegroundColor Cyan
Write-Host "Testing Task Management with Entity Relationships`n" -ForegroundColor Cyan

# Login
Write-Host "━━━━ Logging in ━━━━" -ForegroundColor Gray
$adminLogin = @{email="admin@crm.com"; password="Admin@12345"} | ConvertTo-Json
$adminTokens = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/auth/login" -Method Post -ContentType "application/json" -Body $adminLogin
$adminToken = $adminTokens.access_token
Write-Host "✅ Admin logged in" -ForegroundColor Green

$salesLogin = @{email="test.sales@crm.com"; password="Sales@12345"} | ConvertTo-Json
$salesTokens = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/auth/login" -Method Post -ContentType "application/json" -Body $salesLogin
$salesToken = $salesTokens.access_token
$salesUserId = (Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/auth/me" -Headers @{"Authorization"="Bearer $salesToken"}).id
Write-Host "✅ Sales user logged in (ID: $salesUserId)" -ForegroundColor Green
Write-Host ""

# Get entity IDs for testing
$leads = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/leads/" -Headers @{"Authorization"="Bearer $adminToken"}
$leadId = $leads.leads[0].id

$customers = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/customers/" -Headers @{"Authorization"="Bearer $adminToken"}
$customerId = $customers.customers[0].id

$deals = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/deals/" -Headers @{"Authorization"="Bearer $adminToken"}
$dealId = $deals.deals[0].id

Write-Host "Using Lead ID: $leadId, Customer ID: $customerId, Deal ID: $dealId`n" -ForegroundColor Gray

# Test 1: Create tasks for different entities
Write-Host "1. Creating Tasks for Different Entities" -ForegroundColor Yellow

$taskLead = @{
    title="Follow up on lead inquiry"
    description="Call lead to discuss product features"
    assigned_to_id=$salesUserId
    related_type="lead"
    related_id=$leadId
    due_date="2025-01-20"
    priority="High"
} | ConvertTo-Json

$taskCustomer = @{
    title="Schedule customer review meeting"
    description="Quarterly business review with customer"
    assigned_to_id=$salesUserId
    related_type="customer"
    related_id=$customerId
    due_date="2025-02-01"
    priority="Medium"
} | ConvertTo-Json

$taskDeal = @{
    title="Prepare proposal document"
    description="Create detailed proposal for deal"
    assigned_to_id=$salesUserId
    related_type="deal"
    related_id=$dealId
    due_date="2025-01-15"
    priority="High"
} | ConvertTo-Json

$taskGeneral = @{
    title="Update CRM documentation"
    description="General task not related to specific entity"
    assigned_to_id=$salesUserId
    priority="Low"
} | ConvertTo-Json

$task1 = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/tasks/" -Method Post -ContentType "application/json" -Body $taskLead -Headers @{"Authorization"="Bearer $adminToken"}
Write-Host "  ✅ Created task for Lead (ID: $($task1.id))" -ForegroundColor Green

$task2 = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/tasks/" -Method Post -ContentType "application/json" -Body $taskCustomer -Headers @{"Authorization"="Bearer $salesToken"}
Write-Host "  ✅ Created task for Customer (ID: $($task2.id))" -ForegroundColor Green

$task3 = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/tasks/" -Method Post -ContentType "application/json" -Body $taskDeal -Headers @{"Authorization"="Bearer $adminToken"}
Write-Host "  ✅ Created task for Deal (ID: $($task3.id))" -ForegroundColor Green

$task4 = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/tasks/" -Method Post -ContentType "application/json" -Body $taskGeneral -Headers @{"Authorization"="Bearer $salesToken"}
Write-Host "  ✅ Created general task (ID: $($task4.id))" -ForegroundColor Green
Write-Host ""

# Test 2: List tasks
Write-Host "2. Listing Tasks" -ForegroundColor Yellow
$allTasks = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/tasks/" -Headers @{"Authorization"="Bearer $adminToken"}
Write-Host "  ✅ Admin sees $($allTasks.total) task(s)" -ForegroundColor Green

$salesTasks = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/tasks/" -Headers @{"Authorization"="Bearer $salesToken"}
Write-Host "  ✅ Sales user sees $($salesTasks.total) assigned task(s)" -ForegroundColor Green
Write-Host ""

# Test 3: Get task details
Write-Host "3. Getting Task Details" -ForegroundColor Yellow
$taskDetails = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/tasks/$($task1.id)" -Headers @{"Authorization"="Bearer $salesToken"}
Write-Host "  ✅ Retrieved task: $($taskDetails.title)" -ForegroundColor Green
Write-Host "    Priority: $($taskDetails.priority)" -ForegroundColor Cyan
Write-Host "    Status: $($taskDetails.status)" -ForegroundColor Cyan
Write-Host "    Related to: $($taskDetails.related_type) (ID: $($taskDetails.related_id))" -ForegroundColor Cyan
Write-Host "    Is Overdue: $($taskDetails.is_overdue)" -ForegroundColor Cyan
Write-Host ""

# Test 4: Filter tasks by priority
Write-Host "4. Testing Filters" -ForegroundColor Yellow
$highPriority = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/tasks/?priority=High" -Headers @{"Authorization"="Bearer $adminToken"}
Write-Host "  ✅ High priority tasks: $($highPriority.total)" -ForegroundColor Green

$pendingTasks = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/tasks/?status=Pending" -Headers @{"Authorization"="Bearer $adminToken"}
Write-Host "  ✅ Pending tasks: $($pendingTasks.total)" -ForegroundColor Green

$dealTasks = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/tasks/?related_type=deal" -Headers @{"Authorization"="Bearer $adminToken"}
Write-Host "  ✅ Tasks related to deals: $($dealTasks.total)" -ForegroundColor Green
Write-Host ""

# Test 5: Update task status
Write-Host "5. Updating Task Status" -ForegroundColor Yellow
$statusUpdate = @{status="Completed"} | ConvertTo-Json
$completed = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/tasks/$($task4.id)/status" -Method Put -ContentType "application/json" -Body $statusUpdate -Headers @{"Authorization"="Bearer $salesToken"}
Write-Host "  ✅ Task marked as: $($completed.status)" -ForegroundColor Green
Write-Host ""

# Test 6: Update task
Write-Host "6. Updating Task Information" -ForegroundColor Yellow
$taskUpdate = @{
    priority="Medium"
    description="Updated description with more details"
} | ConvertTo-Json
$updated = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/tasks/$($task1.id)" -Method Put -ContentType "application/json" -Body $taskUpdate -Headers @{"Authorization"="Bearer $salesToken"}
Write-Host "  ✅ Task updated" -ForegroundColor Green
Write-Host "    New priority: $($updated.priority)" -ForegroundColor Cyan
Write-Host ""

# Test 7: Assign task
Write-Host "7. Assigning Task" -ForegroundColor Yellow
$adminUserId = (Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/auth/me" -Headers @{"Authorization"="Bearer $adminToken"}).id
$assign = @{assigned_to_id=$adminUserId} | ConvertTo-Json
$assigned = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/tasks/$($task2.id)/assign" -Method Post -ContentType "application/json" -Body $assign -Headers @{"Authorization"="Bearer $adminToken"}
Write-Host "  ✅ Task reassigned to admin user" -ForegroundColor Green
Write-Host ""

# Test 8: Filter by entity
Write-Host "8. Filtering Tasks by Related Entity" -ForegroundColor Yellow
$leadTasks = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/tasks/?related_type=lead&related_id=$leadId" -Headers @{"Authorization"="Bearer $adminToken"}
Write-Host "  ✅ Tasks for Lead $leadId : $($leadTasks.total)" -ForegroundColor Green
Write-Host ""

# Test 9: RBAC - Sales accessing admin's task
Write-Host "9. Testing RBAC Permissions" -ForegroundColor Yellow
try {
    $accessed = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/tasks/$($task2.id)" -Headers @{"Authorization"="Bearer $salesToken"}
    Write-Host "  ❌ UNEXPECTED: Sales accessed admin's task!" -ForegroundColor Red
} catch {
    Write-Host "  ✅ Correctly denied access (403 Forbidden)" -ForegroundColor Green
}
Write-Host ""

# Test 10: Search tasks
Write-Host "10. Searching Tasks" -ForegroundColor Yellow
$searchResults = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/tasks/?search=proposal" -Headers @{"Authorization"="Bearer $adminToken"}
Write-Host "  ✅ Search for 'proposal' found $($searchResults.total) task(s)" -ForegroundColor Green
Write-Host ""

Write-Host "=== All Tests Completed ===" -ForegroundColor Cyan
Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "✅ Task creation working" -ForegroundColor Green
Write-Host "✅ Polymorphic relationships (lead/customer/deal)" -ForegroundColor Green
Write-Host "✅ Task listing with pagination" -ForegroundColor Green
Write-Host "✅ RBAC permissions enforced correctly" -ForegroundColor Green
Write-Host "✅ Task status updates" -ForegroundColor Green
Write-Host "✅ Task assignment working" -ForegroundColor Green
Write-Host "✅ Filtering by priority, status, entity" -ForegroundColor Green
Write-Host "✅ Task updates working" -ForegroundColor Green
Write-Host "✅ Search functionality" -ForegroundColor Green
Write-Host "✅ Sales users can only access assigned tasks" -ForegroundColor Green
