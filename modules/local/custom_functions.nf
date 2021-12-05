def trimSuffix(String original, String suffix) {
    if(original.endsWith(suffix)) {
        return original.substring(0, original.length() - suffix.length())
    }
    return original
}