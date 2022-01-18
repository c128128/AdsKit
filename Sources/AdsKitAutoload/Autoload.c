#include <stdint.h>

void ads_kit_autoload(void);

__attribute__((constructor))
static void _ads_kit_autoload(void) {
    ads_kit_autoload();
}
