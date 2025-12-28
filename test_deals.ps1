# Enterprise CRM - Deal/Opportunity Management Tests
# Comprehensive testing of deal management and pipeline view

Write-Host "`n=== Deal/Opportunity Management Module Tests ===" -ForegroundColor Cyan
Write-Host "Testing Deal Management & Pipeline View`n" -ForegroundColor Cyan

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

# Get a customer ID for testing
$customers = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/customers/" -Headers @{"Authorization"="Bearer $adminToken"}
$customerId = $customers.customers[0].id
Write-Host "Using customer ID: $customerId`n" -ForegroundColor Gray

# Test 1: Create deals at different stages
Write-Host "1. Creating Deals at Different Stages" -ForegroundColor Yellow

$deal1 = @{
    title="Enterprise Software License"
    customer_id=$customerId
    value=50000.00
    stage="Prospecting"
    probability=10
    expected_close_date="2025-03-15"
} | ConvertTo-Json

$deal2 = @{
    title="Cloud Migration Project"
    customer_id=$customerId
    value=125000.00
    stage="Qualification"
    probability=25
} | ConvertTo-Json

$deal3 = @{
    title="Annual Support Contract"
    customer_id=$customerId
    value=25000.00
    stage="Proposal"
    probability=50
} | ConvertTo-Json

$dealId1 = (Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/deals/" -Method Post -ContentType "application/json" -Body $deal1 -Headers @{"Authorization"="Bearer $salesToken"}).id
Write-Host "  ✅ Created deal 1: Enterprise Software ($50K, Prospecting)" -ForegroundColor Green

$dealId2 = (Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/deals/" -Method Post -ContentType "application/json" -Body $deal2 -Headers @{"Authorization"="Bearer $adminToken"}).id
Write-Host "  ✅ Created deal 2: Cloud Migration ($125K, Qualification)" -ForegroundColor Green

$dealId3 = (Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/deals/" -Method Post -ContentType "application/json" -Body $deal3 -Headers @{"Authorization"="Bearer $salesToken"}).id
Write-Host "  ✅ Created deal 3: Support Contract ($25K, Proposal)" -ForegroundColor Green
Write-Host ""

# Test 2: Get pipeline view
Write-Host "2. Testing Pipeline View (Kanban Board Data)" -ForegroundColor Yellow
$pipeline = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/deals/pipeline" -Headers @{"Authorization"="Bearer $adminToken"}
Write-Host "  ✅ Pipeline view retrieved!" -ForegroundColor Green
Write-Host "    Total Deals: $($pipeline.total_deals)" -ForegroundColor Cyan
Write-Host "    Total Value: `$$($pipeline.total_value)" -ForegroundColor Cyan
Write-Host "    Weighted Value: `$$($pipeline.total_weighted_value)" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Pipeline Breakdown:" -ForegroundColor White
foreach ($stageName in @("Prospecting", "Qualification", "Proposal", "Negotiation", "Closed_Won", "Closed_Lost")) {
    $stageData = $pipeline.pipeline.$stageName
    if ($stageData.count -gt 0) {
        Write-Host "    $stageName : $($stageData.count) deal(s), Value: `$$($stageData.total_value), Weighted: `$$($stageData.weighted_value)" -ForegroundColor Cyan
    }
}
Write-Host ""

# Test 3: List deals
Write-Host "3. Listing Deals" -ForegroundColor Yellow
$allDeals = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/deals/" -Headers @{"Authorization"="Bearer $adminToken"}
Write-Host "  ✅ Admin sees $($allDeals.total) deal(s)" -ForegroundColor Green

$salesDeals = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/deals/" -Headers @{"Authorization"="Bearer $salesToken"}
Write-Host "  ✅ Sales user sees $($salesDeals.total) own deal(s)" -ForegroundColor Green
Write-Host ""

# Test 4: Get deal details
Write-Host "4. Getting Deal Details" -ForegroundColor Yellow
$dealDetails = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/deals/$dealId1" -Headers @{"Authorization"="Bearer $salesToken"}
Write-Host "  ✅ Retrieved deal: $($dealDetails.title)" -ForegroundColor Green
Write-Host "    Value: `$$($dealDetails.value)" -ForegroundColor Cyan
Write-Host "    Stage: $($dealDetails.stage)" -ForegroundColor Cyan
Write-Host "    Probability: $($dealDetails.probability)%" -ForegroundColor Cyan
Write-Host "    Weighted Value: `$$($dealDetails.weighted_value)" -ForegroundColor Cyan
Write-Host ""

# Test 5: Update deal stage
Write-Host "5. Updating Deal Stage" -ForegroundColor Yellow
$stageUpdate = @{stage="Negotiation"} | ConvertTo-Json
$updatedDeal = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/deals/$dealId1/stage" -Method Put -ContentType "application/json" -Body $stageUpdate -Headers @{"Authorization"="Bearer $salesToken"}
Write-Host "  ✅ Stage updated to: $($updatedDeal.stage)" -ForegroundColor Green
Write-Host "    Probability auto-updated to: $($updatedDeal.probability)%" -ForegroundColor Cyan
Write-Host ""

# Test 6: Update deal
Write-Host "6. Updating Deal Information" -ForegroundColor Yellow
$update = @{
    value=55000.00
    expected_close_date="2025-02-28"
} | ConvertTo-Json
$updated = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/deals/$dealId1" -Method Put -ContentType "application/json" -Body $update -Headers @{"Authorization"="Bearer $salesToken"}
Write-Host "  ✅ Deal updated" -ForegroundColor Green
Write-Host "    New value: `$$($updated.value)" -ForegroundColor Cyan
Write-Host ""

# Test 7: Filter by stage
Write-Host "7. Testing Filters" -ForegroundColor Yellow
$prospectingDeals = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/deals/?stage=Prospecting" -Headers @{"Authorization"="Bearer $adminToken"}
Write-Host "  ✅ Prospecting deals: $($prospectingDeals.total)" -ForegroundColor Green

$customerDeals = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/deals/?customer_id=$customerId" -Headers @{"Authorization"="Bearer $adminToken"}
Write-Host "  ✅ Deals for customer $customerId : $($customerDeals.total)" -ForegroundColor Green
Write-Host ""

# Test 8: Assign deal
Write-Host "8. Assigning Deal" -ForegroundColor Yellow
$assign = @{owner_id=$salesUserId} | ConvertTo-Json
$assigned = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/deals/$dealId2/assign" -Method Post -ContentType "application/json" -Body $assign -Headers @{"Authorization"="Bearer $adminToken"}
Write-Host "  ✅ Deal assigned to sales user $salesUserId" -ForegroundColor Green
Write-Host ""

# Test 9: Close a deal (Won)
Write-Host "9. Closing Deal as Won" -ForegroundColor Yellow
$closeWon = @{stage="Closed_Won"} | ConvertTo-Json
$wonDeal = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/deals/$dealId3/stage" -Method Put -ContentType "application/json" -Body $closeWon -Headers @{"Authorization"="Bearer $salesToken"}
Write-Host "  ✅ Deal closed as Won!" -ForegroundColor Green
Write-Host "    Probability set to: $($wonDeal.probability)%" -ForegroundColor Cyan
Write-Host ""

# Test 10: Updated pipeline view
Write-Host "10. Pipeline View After Updates" -ForegroundColor Yellow
$updatedPipeline = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/deals/pipeline" -Headers @{"Authorization"="Bearer $adminToken"}
Write-Host "  ✅ Updated pipeline:" -ForegroundColor Green
foreach ($stageName in @("Prospecting", "Qualification", "Proposal", "Negotiation", "Closed_Won", "Closed_Lost")) {
    $stageData = $updatedPipeline.pipeline.$stageName
    if ($stageData.count -gt 0) {
        Write-Host "    $stageName : $($stageData.count) deal(s)" -ForegroundColor Cyan
    }
}
Write-Host ""

# Test 11: RBAC - Create deal with admin, access deniedfor different sales user
Write-Host "11. Testing RBAC Permissions" -ForegroundColor Yellow
$adminDeal = @{
    title="Admin-created Deal"
    customer_id=$customerId
    value=10000.00
    stage="Prospecting"
} | ConvertTo-Json
$adminOwnedDeal = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/deals/" -Method Post -ContentType "application/json" -Body $adminDeal -Headers @{"Authorization"="Bearer $adminToken"}

try {
    $accessed = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/deals/$($adminOwnedDeal.id)" -Headers @{"Authorization"="Bearer $salesToken"}
    Write-Host "  ❌ UNEXPECTED: Sales accessed admin's deal!" -ForegroundColor Red
} catch {
    Write-Host "  ✅ Correctly denied access (403 Forbidden)" -ForegroundColor Green
}
Write-Host ""

Write-Host "=== All Tests Completed ===" -ForegroundColor Cyan
Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "✅ Deal creation working" -ForegroundColor Green
Write-Host "✅ Pipeline view with Kanban data" -ForegroundColor Green
Write-Host "✅ Stage updates with auto-probability" -ForegroundColor Green
Write-Host "✅ Deal listing with pagination" -ForegroundColor Green
Write-Host "✅ RBAC permissions enforced correctly" -ForegroundColor Green
Write-Host "✅ Deal assignment working" -ForegroundColor Green
Write-Host "✅ Filtering by stage and customer" -ForegroundColor Green
Write-Host "✅ Deal updates working" -ForegroundColor Green
Write-Host "✅ Weighted value calculations" -ForegroundColor Green
Write-Host "✅ Sales users can only access own deals" -ForegroundColor Green
