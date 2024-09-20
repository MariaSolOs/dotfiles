/**
 * Removes the double quotes from a string.
 *
 * @param {string} str
 * @returns string
 */
export const unquoteString = (str) => str.replace(/"/g, '');

/**
 * Capitalizes the given string (the first letter is upper-cased).
 *
 * @param {string} str
 * @returns string
 */
export const capitalize = (str) => str.charAt(0).toUpperCase() + str.slice(1);
