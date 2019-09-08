import { ready, ajaxRequest, showAlert } from './utils'
import Sortable from 'sortablejs'
import {tns} from 'tiny-slider/src/tiny-slider'
import SVG from '../icons/symbol-defs.svg'
import PNGBin from '../icons/png-icons/bin.png'

const plannerRecipeAddData = (id, date) => (
	"recipe_id=" + id + "&planner_date=" + date
)

const plannerRecipeUpdateData = (e) => (
	"recipe_id=" + e.item.id + "&old_date=" + e.item.dataset.parentId + "&new_date=" + e.item.parentNode.id
)

function checkForUpdates(onSuccess) {
  setTimeout(() => fetch("/planner/shopping_list").then((response) => {
    if(response.status != 200){
      setTimeout(() => checkForUpdates(onSuccess), 200)
    } else {
      response.json().then(onSuccess)
    }
  }), 400)
}

const renderShoppingList = (shoppingListPortions) => {

	const ShoppingList = document.querySelector('#planner_shopping_list')

	const ListTopUl = document.createElement('ul')
	ListTopUl.classList.add('planner_sl-recipe_list')

	const OldShoppingListContent = document.querySelector('#planner_shopping_list > ul')

	if (shoppingListPortions.length === 0 ){
		hideShoppingList()
		ListTopUl.innerHTML = '<p>Shopping List is currently empty, move some recipes to your planner to get items added to this list</p>'
	} else {
		shoppingListPortions.forEach(function(portion) {
			const RecipePortionLi = document.createElement('li')
			RecipePortionLi.innerHTML = '<p><label><input type="checkbox" name="planner_shopping_list_portions['+ portion["shopping_list_portion_id"] +'][add]" id="planner_shopping_list_portions_id_add" value="'+ portion["shopping_list_portion_id"] +'"> ' + portion["portion_description"] + '</label></p><h5>Use by date:</h5><p><input type="date" name="planner_shopping_list_portions['+ portion["shopping_list_portion_id"] +'][date]" id="planner_shopping_list_portions_id_date" value="' + portion["max_date"] + '" min="' + portion["min_date"] + '"></p><hr />'
			ListTopUl.appendChild(RecipePortionLi)
		})

		showShoppingList()
	}
	OldShoppingListContent.remove()
	ShoppingList.appendChild(ListTopUl)
}


const showShoppingList = () => {
	const html = document.querySelector('html')
	if (!html.classList.contains('shopping_list_open')) {
		html.classList.add('shopping_list_open')
	}
}

const hideShoppingList = () => {
	const html = document.querySelector('html')
	if (html.classList.contains('shopping_list_open')) {
		html.classList.remove('shopping_list_open')
	}
}

const setupShoppingListButton = () => {
	const html = document.querySelector('html')
	const toggleBtn = document.querySelector('#planner_shopping_list .list_toggle')
	toggleBtn.addEventListener("click", function(){
		html.classList.toggle('shopping_list_open')
	})
}


const addPlannerRecipe = (e) => {
	ajaxRequest(plannerRecipeAddData(e.item.id, e.item.parentNode.id), '/planner/recipe_add')

	const deleteBtn = document.createElement('button')
	deleteBtn.innerHTML = `<svg class="icomoon-icon icon-bin"><use xlink:href="${SVG}#icon-bin"></use></svg><img class="icon-png" src="${PNGBin}"></button>`
	deleteBtn.classList.add('delete', 'list_block--item--action', 'list_block--item--action--btn')

	const parentId = e.item.parentNode.id
	e.item.setAttribute('data-parent-id', parentId)
	e.item.classList.remove('list_block--item--with-bar')

	e.item.appendChild(deleteBtn)
	deleteBtn.addEventListener("click", function(){deletePlannerRecipe(deleteBtn)})

	checkForUpdates(function(shoppingListPortions) {
	  renderShoppingList(shoppingListPortions)
	})

}

const updatePlannerRecipe = (e) => {
	ajaxRequest(plannerRecipeUpdateData(e), '/planner/recipe_update')

	const parentId = e.item.parentNode.id
	e.item.setAttribute('data-parent-id', parentId)

	checkForUpdates(function(shoppingListPortions) {
	  renderShoppingList(shoppingListPortions)
	})
}

const deletePlannerRecipe = (deleteBtn) => {
	const buttonParent = deleteBtn.parentNode
	const dateId = buttonParent.dataset.parentId
	const recipeId = buttonParent.id
	const deleteString = "recipe_id=" + recipeId + "&date=" + dateId
	ajaxRequest(deleteString, '/planner/recipe_delete')

	buttonParent.style.display = 'none'

	checkForUpdates(function(shoppingListPortions) {
	  renderShoppingList(shoppingListPortions)
	})
}

const plannerFn = () => {
	if (document.body.classList.contains('planner_controller', 'index_page')) {
		const slider = tns({
			container: '[data-planner]',
			items: 1,
			slideBy: 1,
			startIndex: 1,
			loop: false,
			gutter: 10,
			edgePadding: 40,
			arrowKeys: true,
			swipeAngle: false,
			controlsContainer: '.tiny-controls',
			nav: false,
			responsive: {
				420: {
					items: 1
				},
				640: {
					items: 2
				},
				900: {
					items: 3
				},
				1200: {
					items: 4
				}
			}
		});

		const recipeList = document.querySelector('[data-recipe-list]')
		const plannerBlocks = document.querySelectorAll('[data-planner] .tiny-slide:not(.yesterday) .tiny-drop')
		new Sortable.create(recipeList, {
			group: {
				name: 'recipe-sharing',
				pull: 'clone',
				put: false,
			},
			sort: false,
			onEnd: function(e) {
				if (e.item.parentNode.classList.contains('tiny-drop')){
					addPlannerRecipe(e)
				}
			}
		})
		plannerBlocks.forEach(function(dayBlock){
			new Sortable.create(dayBlock, {
				group: {
					name: 'recipe-sharing',
					pull: true,
					put: true
				},
				onEnd: function(e) {
					updatePlannerRecipe(e)
				}
			})
		})

		const plannerRecipeDeleteButtons = document.querySelectorAll('.tiny-slide .list_block--item button.delete')

		plannerRecipeDeleteButtons.forEach(function(deleteBtn){
			deleteBtn.addEventListener("click", function(){deletePlannerRecipe(deleteBtn)})
		})

		checkForUpdates(function(shoppingListPortions) {
			renderShoppingList(shoppingListPortions)
		})

	}
	if (document.body.classList.contains('recipes_controller', 'index_page')) {
		const recipeAddToPlannerButtons = document.querySelectorAll('.list_block--action_row .add_recipe_to_planner')
		recipeAddToPlannerButtons.forEach(function(addBtn){
			const recipeId = addBtn.getAttribute('data-recipe-id')
			const date = addBtn.getAttribute('data-date')
			addBtn.addEventListener("click", function(){
				ajaxRequest(plannerRecipeAddData(recipeId, date), '/planner/recipe_add')
				addBtn.style.display = 'none'
				checkForUpdates(function(shoppingListPortions) {
					renderShoppingList(shoppingListPortions)
				})
				showAlert(`Recipe added to your <a href="/planner">planner</a><br />Your shopping list is now updating`)
			})
		})
	}
	if (document.body.classList.contains('recipes_controller', 'show_page')) {
		if (document.querySelector('#add_recipe_to_planner')) {
			const recipeAddToPlannerButton = document.querySelector('#add_recipe_to_planner')
			const recipeId = recipeAddToPlannerButton.getAttribute('data-recipe-id')
			const date = recipeAddToPlannerButton.getAttribute('data-date')
			recipeAddToPlannerButton.addEventListener("click", function(){
				ajaxRequest(plannerRecipeAddData(recipeId, date), '/planner/recipe_add')
				recipeAddToPlannerButton.style.display = 'none'
				checkForUpdates(function(shoppingListPortions) {
					renderShoppingList(shoppingListPortions)
				})
				showAlert(`Recipe added to your <a href="/planner">planner</a><br />Your shopping list is now updating`)
			})
		}
	}

	setupShoppingListButton()

}

ready(plannerFn)
