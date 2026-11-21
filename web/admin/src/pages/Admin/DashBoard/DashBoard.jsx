import BoardTitle from "./BoardTitle/BoardTitle.jsx";
import BoardActive from "./BoardActive/BoardActive.jsx";
import BoardTable from "./BoardTable/BoardTable.jsx";
import Pagination from "../../../components/Pagination/Pagination.jsx";

function DashBoard() {
    return (
        <>
            <BoardTitle />

            <BoardActive />

            <section className="content">

                <BoardTable />

                <Pagination />

            </section>
        </>
    )
}

export default DashBoard;