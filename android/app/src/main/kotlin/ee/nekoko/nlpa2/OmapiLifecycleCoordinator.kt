package ee.nekoko.nlpa2

import java.util.concurrent.atomic.AtomicLong

/** Serializes OMAPI lifecycle and hardware work without blocking Android lifecycle callbacks. */
internal class OmapiLifecycleCoordinator(
        private val enqueue: (() -> Unit) -> Boolean,
) {
    private val generation = AtomicLong()

    @Volatile private var acceptingHardwareOperations = false

    val isAcceptingHardwareOperations: Boolean
        get() = acceptingHardwareOperations

    fun attach(initialize: () -> Boolean): Boolean {
        val token = generation.incrementAndGet()
        acceptingHardwareOperations = false
        return enqueue {
            if (generation.get() == token) {
                val initialized = initialize()
                if (generation.get() == token) {
                    acceptingHardwareOperations = initialized
                }
            }
        }
    }

    fun detach(shutdown: () -> Unit): Boolean {
        generation.incrementAndGet()
        acceptingHardwareOperations = false
        return enqueue(shutdown)
    }

    fun enqueueHardware(onRejected: () -> Unit, operation: () -> Unit): Boolean {
        val token = generation.get()
        return enqueue {
            if (acceptingHardwareOperations && generation.get() == token) {
                operation()
            } else {
                onRejected()
            }
        }
    }
}
