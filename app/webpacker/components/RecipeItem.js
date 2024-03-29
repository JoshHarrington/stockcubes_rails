import React from "react"
import TooltipWrapper from "./TooltipWrapper"
import Icon from "./Icon"
import classNames from 'classnames'
import PropTypes from 'prop-types'

const RecipeItem = props => {

	const {encodedId, width, onDragStart, onDragEnd, className, draggable, children} = props

	return (
		<div
			className={classNames({"w-1/2 sm:w-1/3 md:w-1/4 lg:w-1/5 xl:w-1/6 p-2": !width}, {"w-full py-2": !!width && width === "full"}, "flex sortable--item", className)}
			id={encodedId}
			onDragStart={onDragStart}
			onDragEnd={onDragEnd}
			draggable={draggable}
		>
			<div className="flex bg-primary-400 relative rounded-sm w-full flex-col cursor-move">
				{children}
			</div>
		</div>
	)
}


RecipeItem.propTypes = {
	encodedId: PropTypes.string,
	width: PropTypes.oneOf(["full"])
}

export default RecipeItem
