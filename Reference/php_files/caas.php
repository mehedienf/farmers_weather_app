<?php
ini_set('error_log', 'sms-app-error.log');
require 'bdapps_cass_sdk.php';

// APP Credentials
$appid       = "APP_135901";
$apppassword = "ee8f1b3480139177efec4766103a4d28";

// Initialize SDK objects
$logger = new Logger();
$cass   = new DirectDebitSender(
    "https://developer.bdapps.com/caas/direct/debit",
    $appid,
    $apppassword
);
$sms    = new SmsSender(
    "https://developer.bdapps.com/sms/send",
    $appid,
    $apppassword
);

// Read JSON input from client
$input = json_decode(file_get_contents('php://input'), true);

// Validate input
$number = $input['number'] ?? null;
$amount = $input['amount'] ?? null;

if (!$number || !$amount) {
    echo json_encode(["error" => "Subscriber number and amount are required"]);
    exit;
}

$address = "tel:" . $number;
$trxId   = "TX" . time() . rand(100, 999); // Unique transaction ID

try {
    // Perform Direct Debit
    $status = $cass->cass($trxId, $address, $amount);

    // Log the response
    file_put_contents('USSDERROR.txt', date('Y-m-d H:i:s') . " | $address | $amount | Status: $status\n", FILE_APPEND);

    // Send SMS based on status
    if ($status === "S1000") {
        $sms->sms("Purchase of BDT $amount successful.", $address);
        $response = ["status" => "success", "message" => "Payment successful"];
    } else {
        $sms->sms("Payment failed. Status: $status", $address);
        $response = ["status" => "failed", "message" => "Payment failed: $status"];
    }

} catch (CassException $e) {
    // User does not have sufficient balance or other CAAS error
    $sms->sms("You do not have sufficient balance.", $address);
    $logger->WriteLog("CassException: " . $e->getMessage());
    $response = ["status" => "error", "message" => $e->getMessage()];
} catch (Exception $e) {
    // General errors
    $logger->WriteLog("Exception: " . $e->getMessage());
    $response = ["status" => "error", "message" => $e->getMessage()];
}

// Return JSON response to client
header('Content-Type: application/json');
echo json_encode($response);

?>
