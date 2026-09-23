export function transformDate(date: string, offsetMin: number): string {
	if (date === '') return '';
	// console.log(`Transform before: ${date}`);

	offsetMin = !isNaN(offsetMin) ? offsetMin : new Date(date).getTimezoneOffset();
	const offsetHr = Math.trunc(offsetMin / 60);
	const sign = offsetMin > 0 ? '-' : '+';
	offsetMin -= offsetHr * 60;

	const hrStr = Math.abs(offsetHr).toString().padStart(2, '0');
	const minStr = Math.abs(offsetMin).toString().padStart(2, '0');
	// set seconds when date picker supports it
	const newDate = date + `:00${sign}${hrStr}:${minStr}`;
	// console.log(`Transform after:  ${newDate}`);
	return newDate;
}
