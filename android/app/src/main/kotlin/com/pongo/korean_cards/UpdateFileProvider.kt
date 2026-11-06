package com.pongo.korean_cards

import androidx.core.content.FileProvider

/** Gives the system installer read access to a downloaded update APK. Its own class so it can't clash with plugin providers. */
class UpdateFileProvider : FileProvider()
