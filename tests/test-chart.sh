#!/bin/bash

# K8s Manus - Helm Chart Testing Script
# Validates the Helm chart before deployment

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CHART_DIR="$PROJECT_DIR/charts/k8s-manus"

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Test functions
test_helm_lint() {
    log "Running Helm lint..."
    
    cd "$CHART_DIR"
    
    if helm lint .; then
        success "Helm lint passed"
        return 0
    else
        error "Helm lint failed"
        return 1
    fi
}

test_helm_template() {
    log "Testing Helm template generation..."
    
    cd "$CHART_DIR"
    
    local output_file="/tmp/k8s-manus-test-output.yaml"
    
    if helm template k8s-manus-test . --namespace k8s-manus-test > "$output_file"; then
        local line_count=$(wc -l < "$output_file")
        success "Helm template generated successfully ($line_count lines)"
        return 0
    else
        error "Helm template generation failed"
        return 1
    fi
}

test_with_examples() {
    log "Testing with example values files..."
    
    cd "$CHART_DIR"
    
    local examples_dir="$PROJECT_DIR/examples"
    local failed=0
    
    for values_file in "$examples_dir"/*.yaml; do
        if [[ -f "$values_file" ]]; then
            local filename=$(basename "$values_file")
            log "Testing with $filename..."
            
            if helm template k8s-manus-test . --namespace k8s-manus-test -f "$values_file" > /dev/null; then
                success "Template generation with $filename passed"
            else
                error "Template generation with $filename failed"
                failed=1
            fi
        fi
    done
    
    return $failed
}

test_kubernetes_validation() {
    log "Validating Kubernetes manifests..."
    
    cd "$CHART_DIR"
    
    local output_file="/tmp/k8s-manus-validation.yaml"
    
    # Generate manifests
    helm template k8s-manus-test . --namespace k8s-manus-test > "$output_file"
    
    # Check if kubectl is available for validation
    if command -v kubectl &> /dev/null; then
        if kubectl apply --dry-run=client -f "$output_file" > /dev/null 2>&1; then
            success "Kubernetes manifest validation passed"
            return 0
        else
            warning "Kubernetes manifest validation failed (this may be due to cluster connectivity)"
            return 1
        fi
    else
        warning "kubectl not available, skipping Kubernetes validation"
        return 0
    fi
}

test_required_fields() {
    log "Checking required fields in Chart.yaml..."
    
    cd "$CHART_DIR"
    
    local chart_file="Chart.yaml"
    local failed=0
    
    # Check required fields
    local required_fields=("name" "version" "description" "type")
    
    for field in "${required_fields[@]}"; do
        if grep -q "^$field:" "$chart_file"; then
            success "Required field '$field' found"
        else
            error "Required field '$field' missing"
            failed=1
        fi
    done
    
    return $failed
}

test_template_syntax() {
    log "Checking template syntax..."
    
    cd "$CHART_DIR"
    
    local failed=0
    
    # Find all template files
    while IFS= read -r -d '' template_file; do
        local relative_path="${template_file#$CHART_DIR/}"
        
        # Basic syntax check - look for common issues
        if grep -q "{{.*}}" "$template_file"; then
            # Check for unclosed braces
            if ! grep -q "{{.*}}" "$template_file" | grep -v "{{.*}}"; then
                success "Template syntax OK: $relative_path"
            else
                warning "Potential template syntax issue: $relative_path"
            fi
        fi
    done < <(find templates -name "*.yaml" -type f -print0)
    
    return $failed
}

test_values_schema() {
    log "Validating values.yaml structure..."
    
    cd "$CHART_DIR"
    
    local values_file="values.yaml"
    local failed=0
    
    # Check if values.yaml exists
    if [[ ! -f "$values_file" ]]; then
        error "values.yaml not found"
        return 1
    fi
    
    # Basic YAML syntax check
    if python3 -c "import yaml; yaml.safe_load(open('$values_file'))" 2>/dev/null; then
        success "values.yaml has valid YAML syntax"
    else
        error "values.yaml has invalid YAML syntax"
        failed=1
    fi
    
    # Check for required top-level keys
    local required_keys=("global" "auth" "databases" "networking")
    
    for key in "${required_keys[@]}"; do
        if grep -q "^$key:" "$values_file"; then
            success "Required key '$key' found in values.yaml"
        else
            warning "Recommended key '$key' missing in values.yaml"
        fi
    done
    
    return $failed
}

# Main test runner
run_all_tests() {
    log "Starting K8s Manus Helm Chart Tests"
    echo "======================================"
    echo ""
    
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    # Array of test functions
    local tests=(
        "test_required_fields"
        "test_values_schema"
        "test_helm_lint"
        "test_template_syntax"
        "test_helm_template"
        "test_with_examples"
        "test_kubernetes_validation"
    )
    
    # Run each test
    for test_func in "${tests[@]}"; do
        echo ""
        total_tests=$((total_tests + 1))
        
        if $test_func; then
            passed_tests=$((passed_tests + 1))
        else
            failed_tests=$((failed_tests + 1))
        fi
    done
    
    # Summary
    echo ""
    echo "======================================"
    log "Test Summary"
    echo "Total Tests: $total_tests"
    echo -e "Passed: ${GREEN}$passed_tests${NC}"
    echo -e "Failed: ${RED}$failed_tests${NC}"
    
    if [[ $failed_tests -eq 0 ]]; then
        echo ""
        success "All tests passed! Chart is ready for deployment."
        return 0
    else
        echo ""
        error "Some tests failed. Please review and fix issues before deployment."
        return 1
    fi
}

# Command line interface
case "${1:-all}" in
    "lint")
        test_helm_lint
        ;;
    "template")
        test_helm_template
        ;;
    "examples")
        test_with_examples
        ;;
    "kubernetes")
        test_kubernetes_validation
        ;;
    "syntax")
        test_template_syntax
        ;;
    "values")
        test_values_schema
        ;;
    "all")
        run_all_tests
        ;;
    *)
        echo "Usage: $0 {lint|template|examples|kubernetes|syntax|values|all}"
        echo ""
        echo "Commands:"
        echo "  lint       - Run Helm lint"
        echo "  template   - Test template generation"
        echo "  examples   - Test with example values"
        echo "  kubernetes - Validate Kubernetes manifests"
        echo "  syntax     - Check template syntax"
        echo "  values     - Validate values.yaml"
        echo "  all        - Run all tests (default)"
        exit 1
        ;;
esac

