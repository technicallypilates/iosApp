import XCTest
@testable import TechnicallyPilates

class ResourceMonitorTests: XCTestCase {
    var resourceMonitor: ResourceMonitor!
    
    override func setUp() {
        super.setUp()
        resourceMonitor = ResourceMonitor.shared
    }
    
    override func tearDown() {
        resourceMonitor = nil
        super.tearDown()
    }
    
    func testResourceReport() {
        let report = resourceMonitor.getResourceReport()
        
        // Verify report structure
        XCTAssertNotNil(report)
        XCTAssertNotNil(report.cpuUsage)
        XCTAssertNotNil(report.memoryUsage)
        XCTAssertNotNil(report.batteryDrain)
        XCTAssertNotNil(report.temperature)
        
        // Verify value ranges
        XCTAssertGreaterThanOrEqual(report.cpuUsage, 0)
        XCTAssertLessThanOrEqual(report.cpuUsage, 100)
        XCTAssertGreaterThanOrEqual(report.memoryUsage, 0)
        XCTAssertLessThanOrEqual(report.memoryUsage, 100)
        XCTAssertGreaterThanOrEqual(report.batteryDrain, 0)
        XCTAssertGreaterThanOrEqual(report.temperature, 0)
    }
    
    func testProcessQueuedRequests() {
        // Start monitoring
        resourceMonitor.startMonitoring()
        
        // Process queued requests
        resourceMonitor.processQueuedRequests()
        
        // Verify that checkResources was called
        // Note: This is an indirect test as we can't directly verify the internal state
        // without exposing it for testing
    }
    
    func testMonitoringLifecycle() {
        // Start monitoring
        resourceMonitor.startMonitoring()
        
        // Stop monitoring
        resourceMonitor.stopMonitoring()
        
        // Verify monitoring was stopped
        // Note: This is an indirect test as we can't directly verify the internal state
        // without exposing it for testing
    }
    
    func testResourceThresholds() {
        let report = resourceMonitor.getResourceReport()
        
        // Verify health check
        let isHealthy = report.isHealthy
        XCTAssertNotNil(isHealthy)
        
        // Verify thresholds
        if report.cpuUsage >= 80 {
            XCTAssertFalse(isHealthy)
        }
        if report.memoryUsage >= 80 {
            XCTAssertFalse(isHealthy)
        }
        if report.batteryDrain >= 5 {
            XCTAssertFalse(isHealthy)
        }
        if report.temperature >= 40 {
            XCTAssertFalse(isHealthy)
        }
    }
}