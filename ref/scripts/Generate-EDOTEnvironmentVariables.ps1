# More practical output for EDOT migration
function Generate-EDOTConfiguration {
    param($AppPoolName, $AppDynamicsConfig)
    
    return @{
        AppPoolName = $AppPoolName
        EnvironmentVariables = @{
            "OTEL_SERVICE_NAME" = $AppDynamicsConfig.Application
            "OTEL_RESOURCE_ATTRIBUTES" = "deployment.environment=production,service.namespace=eai-$EAICode"
            "OTEL_EXPORTER_OTLP_ENDPOINT" = "https://your-elastic-endpoint:443"
            "OTEL_DOTNET_AUTO_TRACES_INSTRUMENTATION_ENABLED" = "true"
        }
        WebConfigChanges = @{
            # HttpModule additions for .NET Framework
        }
    }
}