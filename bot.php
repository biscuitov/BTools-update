<?php

require_once('simplevk-master/autoload.php');
use DigitalStar\vk_api\VK_api as vk_api; 

const VK_KEY = "a1c59e91e16576c4633b07228cf3dce1f75cef0f58815cb0ad61b0dae384ec0d8d8029923793b572ab08f";  
const ACCESS_KEY = "09b916e4";   
const VERSION = "5.126";

$vk = vk_api::create(VK_KEY, VERSION)->setConfirm(ACCESS_KEY);

$vk->initVars($peer_id, $message, $payload, $vk_id, $type, $data); 

$vk_id = $data->object->from_id; 
$message = $data->object->text; 

$date = date("d.m.Y  H:i");


if ($data->type == 'message_new') {

    if ($message == '!тест') {

        $vk->sendMessage($peer_id, "иди нахуй");

    }
    if ($message == '!дата') {

        $vk->sendMessage($peer_id, $date);

    }

}
	