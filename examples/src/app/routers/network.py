from fastapi import APIRouter, HTTPException
from app.models import NetworkTestSummary, NetworkTestResult
from app.services.network_service import NetworkTestService
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/network", tags=["network"])

# Service instance
network_service = NetworkTestService()


@router.get("/test", response_model=NetworkTestSummary)
async def run_network_tests():
    """Run comprehensive network connectivity tests"""
    try:
        test_summary = await network_service.run_connectivity_tests()
        return test_summary
    except Exception as e:
        logger.error(f"Error running network tests: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/test/{service_name}", response_model=NetworkTestResult)
async def test_specific_service(service_name: str):
    """Test connectivity to a specific Azure service"""
    try:
        test_result = await network_service.test_specific_service_connectivity(service_name)
        return test_result
    except Exception as e:
        logger.error(f"Error testing service {service_name}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/status")
async def get_network_status():
    """Get quick network status overview"""
    try:
        test_summary = await network_service.run_connectivity_tests()
        
        return {
            "overall_status": test_summary.overall_status,
            "reachable_endpoints": test_summary.reachable_endpoints,
            "total_endpoints": test_summary.total_endpoints,
            "average_response_time_ms": test_summary.average_response_time_ms,
            "last_test_time": test_summary.last_test_time
        }
    except Exception as e:
        logger.error(f"Error getting network status: {e}")
        raise HTTPException(status_code=500, detail=str(e))