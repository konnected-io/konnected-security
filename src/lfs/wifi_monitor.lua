local function monitor()
    print("Heap: ", node.heap(), 'Monitoring WiFi for disconnect')
    wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
        print("Heap: ", node.heap(), "Connection to WiFi ", T.SSID, 'lost. Reason Code:', T.reason, ' - Reconnecting')
        wifi.sta.disconnect()
        wifi.sta.connect()
    end)
end

return { monitor = monitor}
