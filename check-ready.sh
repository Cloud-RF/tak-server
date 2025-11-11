#!/bin/bash

# TAK Server Readiness Checker
# This script checks if your system is ready to run the TAK Server setup

echo "=========================================="
echo "TAK Server Readiness Check"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

checks_passed=0
checks_failed=0

# Check 1: Docker installed
echo -n "1. Checking Docker installation... "
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Installed${NC}"
    docker --version
    ((checks_passed++))
else
    echo -e "${RED}✗ Not installed${NC}"
    echo "   Install Docker: apt-get install docker.io"
    ((checks_failed++))
fi
echo ""

# Check 2: Docker Compose installed
echo -n "2. Checking Docker Compose... "
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null 2>&1; then
    echo -e "${GREEN}✓ Installed${NC}"
    if command -v docker-compose &> /dev/null; then
        docker-compose --version
    else
        docker compose version
    fi
    ((checks_passed++))
else
    echo -e "${RED}✗ Not installed${NC}"
    echo "   Install Docker Compose: apt-get install docker-compose"
    ((checks_failed++))
fi
echo ""

# Check 3: Docker daemon running
echo -n "3. Checking if Docker daemon is running... "
if docker ps &> /dev/null; then
    echo -e "${GREEN}✓ Running${NC}"
    ((checks_passed++))
else
    echo -e "${RED}✗ Not running${NC}"
    echo "   Start Docker: sudo systemctl start docker"
    echo "   Or: sudo service docker start"
    ((checks_failed++))
fi
echo ""

# Check 4: Required utilities
echo -n "4. Checking for required utilities... "
missing_utils=""
for util in unzip netstat ifconfig; do
    if ! command -v $util &> /dev/null; then
        missing_utils="$missing_utils $util"
    fi
done

if [ -z "$missing_utils" ]; then
    echo -e "${GREEN}✓ All installed (unzip, netstat, ifconfig)${NC}"
    ((checks_passed++))
else
    echo -e "${RED}✗ Missing:$missing_utils${NC}"
    echo "   Install missing tools: apt-get install net-tools unzip"
    ((checks_failed++))
fi
echo ""

# Check 5: TAK Server release file
echo -n "5. Checking for TAK Server release ZIP... "
if ls *-RELEASE-*.zip 1> /dev/null 2>&1; then
    echo -e "${GREEN}✓ Found${NC}"
    ls -lh *-RELEASE-*.zip | awk '{print "   " $9 " (" $5 ")"}'
    ((checks_passed++))
else
    echo -e "${YELLOW}✗ Not found${NC}"
    echo "   Download from: https://tak.gov/products/tak-server"
    echo "   Place the ZIP file in this directory: $(pwd)"
    echo ""
    echo "   Recommended releases:"
    echo "   - takserver-docker-5.2-RELEASE-43.zip (Latest)"
    echo "   - takserver-docker-5.1-RELEASE-50.zip"
    ((checks_failed++))
fi
echo ""

# Check 6: Required ports
echo "6. Checking required ports..."
required_ports=(5432 8089 8443 8444 8446 9000 9001)
ports_in_use=0

for port in "${required_ports[@]}"; do
    if netstat -lant 2>/dev/null | grep -w ":$port" &> /dev/null; then
        echo -e "   Port $port: ${RED}✗ In use${NC}"
        ((ports_in_use++))
    else
        echo -e "   Port $port: ${GREEN}✓ Available${NC}"
    fi
done

if [ $ports_in_use -eq 0 ]; then
    ((checks_passed++))
else
    echo -e "   ${YELLOW}Warning: $ports_in_use port(s) in use${NC}"
    echo "   Find process using port: sudo netstat -plant | grep <PORT>"
    ((checks_failed++))
fi
echo ""

# Check 7: Disk space
echo -n "7. Checking disk space... "
available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$available_space" -ge 10 ]; then
    echo -e "${GREEN}✓ ${available_space}GB available${NC}"
    ((checks_passed++))
else
    echo -e "${YELLOW}! Only ${available_space}GB available${NC}"
    echo "   Recommended: At least 10GB free space"
    ((checks_failed++))
fi
echo ""

# Check 8: Memory
echo -n "8. Checking available memory... "
total_mem=$(free -g | awk 'NR==2 {print $2}')
if [ "$total_mem" -ge 4 ]; then
    echo -e "${GREEN}✓ ${total_mem}GB RAM${NC}"
    ((checks_passed++))
else
    echo -e "${YELLOW}! Only ${total_mem}GB RAM${NC}"
    echo "   Recommended: At least 4GB RAM"
    echo "   You can adjust memory allocation during setup"
    ((checks_failed++))
fi
echo ""

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
echo -e "Checks passed: ${GREEN}$checks_passed${NC}"
echo -e "Checks failed: ${RED}$checks_failed${NC}"
echo ""

if [ $checks_failed -eq 0 ]; then
    echo -e "${GREEN}✓ Your system is ready!${NC}"
    echo ""
    echo "To start the setup, run:"
    echo "  ./scripts/setup.sh"
elif [ $checks_failed -eq 1 ] && ! ls *-RELEASE-*.zip 1> /dev/null 2>&1; then
    echo -e "${YELLOW}! Almost ready!${NC}"
    echo ""
    echo "You just need to download the TAK Server release:"
    echo "  1. Go to: https://tak.gov/products/tak-server"
    echo "  2. Download a release ZIP (e.g., takserver-docker-5.2-RELEASE-43.zip)"
    echo "  3. Place it in this directory: $(pwd)"
    echo "  4. Run: ./scripts/setup.sh"
else
    echo -e "${RED}! Please fix the issues above before proceeding${NC}"
    echo ""
    echo "See SETUP_GUIDE.md for detailed instructions"
fi
echo ""
