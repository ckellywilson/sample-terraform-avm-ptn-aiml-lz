import socket
import time
import asyncio
from typing import List
from app.models import NetworkTestResult, NetworkTestSummary
from app.config import settings
import logging

logger = logging.getLogger(__name__)


class NetworkTestService:
    def __init__(self):
        self.endpoints = settings.test_endpoints
    
    async def test_endpoint_connectivity(self, endpoint: str, port: int = 443, timeout: float = 5.0) -> NetworkTestResult:
        """Test connectivity to a specific endpoint"""
        try:
            start_time = time.time()
            
            # Resolve DNS first
            try:
                ip_address = socket.gethostbyname(endpoint)
            except socket.gaierror as e:
                return NetworkTestResult(
                    endpoint=endpoint,
                    is_reachable=False,
                    error_message=f"DNS resolution failed: {str(e)}"
                )
            
            # Test TCP connectivity
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(timeout)
                result = sock.connect_ex((ip_address, port))
                sock.close()
                
                end_time = time.time()
                response_time_ms = (end_time - start_time) * 1000
                
                if result == 0:
                    return NetworkTestResult(
                        endpoint=endpoint,
                        is_reachable=True,
                        response_time_ms=response_time_ms,
                        ip_address=ip_address
                    )
                else:
                    return NetworkTestResult(
                        endpoint=endpoint,
                        is_reachable=False,
                        ip_address=ip_address,
                        error_message=f"Connection failed (code: {result})"
                    )
                    
            except Exception as e:
                return NetworkTestResult(
                    endpoint=endpoint,
                    is_reachable=False,
                    ip_address=ip_address,
                    error_message=f"Connection error: {str(e)}"
                )
                
        except Exception as e:
            return NetworkTestResult(
                endpoint=endpoint,
                is_reachable=False,
                error_message=f"Test failed: {str(e)}"
            )
    
    async def run_connectivity_tests(self) -> NetworkTestSummary:
        """Run connectivity tests for all configured endpoints"""
        logger.info(f"Running connectivity tests for {len(self.endpoints)} endpoints")
        
        # Run tests concurrently
        tasks = [self.test_endpoint_connectivity(endpoint) for endpoint in self.endpoints]
        test_results = await asyncio.gather(*tasks)
        
        # Calculate summary statistics
        reachable_count = sum(1 for result in test_results if result.is_reachable)
        unreachable_count = len(test_results) - reachable_count
        
        # Calculate average response time for reachable endpoints
        reachable_times = [r.response_time_ms for r in test_results if r.is_reachable and r.response_time_ms]
        avg_response_time = sum(reachable_times) / len(reachable_times) if reachable_times else None
        
        # Determine overall status
        if reachable_count == len(test_results):
            overall_status = "healthy"
        elif reachable_count > len(test_results) / 2:
            overall_status = "degraded"
        else:
            overall_status = "unhealthy"
        
        summary = NetworkTestSummary(
            total_endpoints=len(test_results),
            reachable_endpoints=reachable_count,
            unreachable_endpoints=unreachable_count,
            average_response_time_ms=avg_response_time,
            test_results=test_results,
            overall_status=overall_status
        )
        
        logger.info(f"Network test completed: {reachable_count}/{len(test_results)} endpoints reachable")
        return summary
    
    async def test_specific_service_connectivity(self, service_name: str) -> NetworkTestResult:
        """Test connectivity to a specific Azure service"""
        service_endpoints = {
            "openai": "privatelink.openai.azure.com",
            "cosmos": "privatelink.documents.azure.com", 
            "storage": "privatelink.blob.core.windows.net",
            "keyvault": "privatelink.vaultcore.azure.net",
            "apim": "privatelink.azure-api.net"
        }
        
        endpoint = service_endpoints.get(service_name.lower())
        if not endpoint:
            return NetworkTestResult(
                endpoint=service_name,
                is_reachable=False,
                error_message=f"Unknown service: {service_name}"
            )
        
        return await self.test_endpoint_connectivity(endpoint)