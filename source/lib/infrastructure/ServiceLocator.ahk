#Requires AutoHotkey v2.0

/**
 * Class: ServiceLocator
 * Provides a centralized registry for application services with dynamic property access.
 */
class ServiceLocator {
    /** @prop {Map} services - Internal storage for service instances */
    static services := Map()

    /**
     * Method: Register
     * Registers a service instance and dynamically creates a shortcut property.
     * @param {String} name - The service identifier (e.g., "Config")
     * @param {Object} serviceInstance - The instance to register
     */
    static Register(name, serviceInstance) {
        this.services[name] := serviceInstance

        ; Dynamically define a property on the class if it doesn't exist.
        ; This allows access via ServiceLocator.Name instead of ServiceLocator.Get("Name").
        if !this.HasProp(name) {
            this.DefineProp(name, {
                get: (sl) => sl.Get(name)
            })
        }
    }

    /**
     * Method: Get
     * Retrieves a registered service instance.
     * @param {String} name - The service identifier
     * @returns {Object} The service instance
     */
    static Get(name) {
        if !this.services.Has(name) {
            throw Error("Service not registered: " . name)
        }
        return this.services[name]
    }
}
